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

  # CloudFront assigns a domain name to each distribution, such as d111111abcdef8.cloudfront.net
  # If you want to use a custom domain like foobar.mydomain.com you have let CloudFront know
  # which ones.
  #
  # You still have to create the DNS record, this just tells CloudFront what domain you expect
  # to use.
  #
  # See official docs for more information:
  # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/CNAMEs.html
  #
  aliases = [var.domain]

  # No restrictions - the site should be available everywhere
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # For requests to the root of the URL, e.g.
  #
  # mydomain.com/
  #
  # we return the contents of
  #
  # mydomain.com/index.html
  #
  # This doesn't apply to subdirectories, e.g.
  #
  # example.mads-hartmann.com/subdirectory
  #
  # Does _not_ serve the contents of
  #
  # example.mads-hartmann.com/subdirectory/index.html
  #
  # TODO: What if you wanted that? Do you have to use a website bucket?
  #
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

resource "aws_route53_record" "records" {

  for_each = toset(["A", "AAAA"])

  zone_id = var.route53_zone_id
  name    = var.domain
  type    = each.value

  # We're using an alias record which are like CNAME records, but they can be
  # assigned to top-level domaiins like mads-hartmann.com
  #
  # See offiicial docs for more information
  # https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html
  #
  alias {
    name    = aws_cloudfront_distribution.distribution.domain_name
    zone_id = aws_cloudfront_distribution.distribution.hosted_zone_id

    # We're using Simple Routing, e.g. not weighted, failover, geolocation or any
    # of the more advanced features, so we don't need to evaluate the target health.
    evaluate_target_health = false
  }


}

#
# IAM User for scripting deploys
#

# TODO: Uploading to S3 bucket
# TODO: Invalidating CloudFront cache
