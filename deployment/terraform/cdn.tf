resource "aws_cloudfront_distribution" "site" {
  origin {
    domain_name = "${aws_route53_record.origin.fqdn}"
    origin_id   = "originWebsite"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled          = true
  http_version     = "http2"
  comment          = "GeoTrellis Website (${var.environment})"
  retain_on_delete = true

  price_class = "${var.cdn_price_class}"

  # The trailing period at the end of the name is stripped off to comply with CloudFront's CNAME policy.
  aliases = ["${replace(data.aws_route53_zone.external.name, "/.$/", "")}", "www.${replace(data.aws_route53_zone.external.name, "/.$/", "")}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "originWebsite"

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    compress               = false
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 300
  }

  logging_config {
    include_cookies = false
    bucket          = "${data.terraform_remote_state.core.logs_bucket_id}.s3.amazonaws.com"
    prefix          = "CloudFront/Site/"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "${var.ssl_certificate_arn}"
    minimum_protocol_version = "TLSv1"
    ssl_support_method       = "sni-only"
  }
}

resource "aws_cloudfront_distribution" "docs" {
  origin {
    domain_name = "${var.docs_website_url}"
    origin_id   = "originDocs"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    custom_header {
      name  = "RTD-SLUG"
      value = "geotrellis"
    }
  }

  enabled          = true
  http_version     = "http2"
  comment          = "GeoTrellis Docs (${var.environment})"
  retain_on_delete = true

  price_class = "${var.cdn_price_class}"

  # The trailing period at the end of the name is stripped off to comply with CloudFront's CNAME policy.
  aliases = ["docs.${replace(data.aws_route53_zone.external.name, "/.$/", "")}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "originDocs"

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    compress               = false
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 300
  }

  logging_config {
    include_cookies = false
    bucket          = "${data.terraform_remote_state.core.logs_bucket_id}.s3.amazonaws.com"
    prefix          = "CloudFront/Docs/"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "${var.ssl_certificate_arn}"
    minimum_protocol_version = "TLSv1"
    ssl_support_method       = "sni-only"
  }
}
