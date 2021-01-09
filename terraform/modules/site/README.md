# Site

A terraform module for creating a simple static site that's stored on S3 and served by CloudFront.

Features

- It should serve index.html in the root (CF allows this by setting default_root_object)
- It should serve index.html in subdirectories (CF doesn't allow this, so this was achieved by associating a lambda@edge function with CF which does the request re-writing)
- It should show a 404 page when requesting a resource that doesn't exist (achieved using CF custom error responses)
- TODO: It should have basic DOS prevention (achieved by associating a WAF with CF)
- TODO: It should be possible to get viewing statistics
- TODO: Cost calculator for the site

Goals

- The S3 bucket should be completely private - a pure implementation detail - it shouldn't be possible to reach the content without going through CF.

Resources

- A private S3 bucket for hosting the static files
- An [Origin Access Identity (OAI)](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html) to give CloudFront access to the S3 bucket.
- A CloudFront distribution for serving and caching the contents in s3
- Alias record for domain
- Lambda@edge function to serve index.html for subdirectories
- WAF

## TODOs

- [ ] Consider using [aws_s3_bucket_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) to really ensure that nothing in the bucket can be public.

## Implementation

### Why not use CNAME directly to S3 website-enabled bucket

- I want caching (which CloudFront provides)
- I want a WAF for basic protection against attacks
- I want HTTPS (which website buckets don't support afaik)

### Why not use s3 website-enabled bucket for the CloudFront origin

- The objects in website-enabled bucket can't be private
- The S3 website URL would be public if discovered, which means people could circumvent caching.

## Based on

- [Implementing Default Directory Indexes in Amazon S3-backed Amazon CloudFront Origins Using Lambda@Edge](https://aws.amazon.com/blogs/compute/implementing-default-directory-indexes-in-amazon-s3-backed-amazon-cloudfront-origins-using-lambdaedge/)
- [Restricting Access to Amazon S3 Content by Using an Origin Access Identity](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- https://github.com/twstewart42/terraform-aws-cloudfront-s3-website-lambda-edge (similar implementation)
