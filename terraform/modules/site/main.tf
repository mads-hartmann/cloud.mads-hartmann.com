locals {
  # TODO: What is this?
  s3_origin_id = "site-${var.domain}"
}

#
# S3 bucket for hosting the static files
#

resource "aws_s3_bucket" "bucket" {
  bucket = var.domain
  acl    = "private"

  tags = {
    Name    = var.domain
    Project = var.domain
  }

  # No need for versioning.
  versioning {
    enabled = false
  }
}

#
# CloudFront distribution for caching
#

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Read-only access to the S3 buckett from CloudFront"
}

resource "aws_cloudfront_distribution" "distribution" {

  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  comment = "Distribution for ${var.domain}"

  tags = {
    Name    = var.domain
    Project = var.domain
  }

  # TODO: Are theese needed?
  aliases = [var.domain]

  # No restrictions - the site should be available everywhere
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # TODO: Describe
  default_root_object = "index.html"

  default_cache_behavior {
    # All methods are allowed
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]

    # We only cache GET and HEAD
    cached_methods = ["GET", "HEAD"]

    target_origin_id = local.s3_origin_id

    forwarded_values {
      # Don't forward query strings, I don't use them and forwarding them would
      # mean people could use them to bust the caching.
      query_string = false

      cookies {
        # Same for cookies
        forward = "none"
      }
    }

    # I use HTTPS for all my sites.
    viewer_protocol_policy = "redirect-to-https"
  }

  # TODO
  price_class = "PriceClass_200"

  # Use the SSL certificate provided.
  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arn
    # Only accept HTTPS connections from viewers that support SNI (server name indication)
    # This is recommended by AWS.
    ssl_support_method = "sni-only"
  }
}

#
#
#

data "aws_iam_policy_document" "s3_readony_policy_document" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]

    # TODO: Describe what principals are
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.s3_readony_policy_document.json
}

#
# DNS - Route53
#

# TODO: Implement

#
# IAM User for scripting deploys
#

# TODO: Uploading to S3 bucket
# TODO: Invalidating CloudFront cache
