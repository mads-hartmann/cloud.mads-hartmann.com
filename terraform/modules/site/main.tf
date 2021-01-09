locals {
  # TODO: What is this?
  s3_origin_id = "site-${var.domain}"

  # Some atributes can't have . in the name, so in those cases
  # we'll use this instead. Example:
  #
  #   example.mads-hartmann.com becomes
  #
  # becomes:
  #
  #   example-mads-hartmann-com
  hyphened_domain = replace(var.domain, ".", "-")

  # Path to zip file for the lambda.
  lambda_zip_path = "${path.module}/lambda/routing.js.zip"

  # Share tags between resources
  tags = {
    Name    = var.domain
    Project = var.domain
  }
}

#
# S3 bucket for hosting the static files
#

resource "aws_s3_bucket" "bucket" {
  bucket = var.domain
  acl    = "private"

  tags = local.tags

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

  tags = local.tags

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
  # To make that work, we use the Lambda@edge
  #
  default_root_object = "index.html"

  # If the origin returns 403 (which s3 does if an object doesn't exist)
  # then we try to serve the 404.html page instead
  #
  # TODO: This assumes that there is a 404.html page in the bucket, so perhaps
  #       we should make this an input variable instead.
  custom_error_response {
    error_code            = 403
    response_code         = 404
    error_caching_min_ttl = 0
    response_page_path    = "/404.html"
  }

  default_cache_behavior {
    # All methods are allowed
    # TODO: For a static site, we probably only want GET/HEAD/OPTIONS
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]

    # We only cache GET and HEAD
    cached_methods = ["GET", "HEAD"]

    target_origin_id = local.s3_origin_id

    lambda_function_association {
      # Invoke the lambda before CloudFront forwards a request to the origin (origin request)
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.routing.qualified_arn
      include_body = false
    }

    forwarded_values {
      # Don't forward query strings to the origin.
      # As this distribution is just serving static sites we don't need the query string.
      # Leaving it out means people can't bust the cache by appending query strings to requests.
      query_string = false

      cookies {
        # Same for cookies
        forward = "none"
      }
    }

    # I use HTTPS for all my sites.
    viewer_protocol_policy = "redirect-to-https"

    # TODO:
    # - Only 0 while debugging lambda code
    # - I should pick the default values otherwise, but hardcode them.
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
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
# Routing - Lambda
#

data "archive_file" "lambda" {
  type        = "zip"
  output_path = local.lambda_zip_path
  source_file = "${path.module}/lambda/routing.js"
}

resource "aws_iam_role_policy" "log_policy" {
  name = "${local.hyphened_domain}-lambda-log-policy"
  role = aws_iam_role.lambda.id

  #
  # For the log groups:
  # In a nutshell, these are the permissions that the function needs to create the necessary CloudWatch log group and log stream, and to put the log events so that the function is able to write logs when it executes.
  #
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# TODO: Describe why it needs the assume role
resource "aws_iam_role" "lambda" {
  name        = "${local.hyphened_domain}-lambda-assume-role"
  description = "TODO"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "routing" {
  filename         = local.lambda_zip_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  function_name = "${local.hyphened_domain}-routing"
  handler       = "routing.handler"

  role = aws_iam_role.lambda.arn

  # TODO: What does this mean?
  publish = true

  runtime = "nodejs12.x"

  tags = local.tags
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

# TODO

#
# Basic WAF protection
#

# TODO: Uploading to S3 bucket
# TODO: Invalidating CloudFront cache
