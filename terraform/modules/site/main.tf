
# S3 bucket
# CloudFront distribution
# IAM User but uploading to bucket, invalidating CloudFront cache
# Route53?

locals {
  s3_origin_id = "site-${var.domain}"
}

#
# S3 bucket for hosting the static files
#

resource "aws_s3_bucket" "bucket" {
  bucket = var.domain
  acl    = "private"
}

#
# CloudFront distribution for caching
#

resource "aws_cloudfront_distribution" "distribution" {

  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/ABCDEFG1234567"
    }
  }

  enabled         = true
  is_ipv6_enabled = true

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

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
