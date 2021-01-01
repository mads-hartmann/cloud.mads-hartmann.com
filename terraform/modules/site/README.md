# Site

A terraform module for creating a simple static site that's stored on S3 and served by CloudFront.

- A private S3 bucket for hosting the static files
- An [Origin Access Identity (OAI)](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html) to give CloudFront access to the S3 bucket.
- A CloudFront distribution for serving and caching the contents in s3

## TODOs

- Consider using [aws_s3_bucket_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) to really ensure that nothing in the bucket can be public.

## Inputs

- domain: Example example.mads-hartmann.com
- iam_certificate_arn: ARN of the ACM managed SSL certificate. It must cover the domain.

## Decisions

- Decided to not define the SSL certificate in the module as you might want to the same certificate for many sites, e.g. if you have a wild-card certificate like `*.mads-hartmann.com`.
- TODO: Why not just use a S3 website bucket

## Based on

- [Restricting Access to Amazon S3 Content by Using an Origin Access Identity](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
