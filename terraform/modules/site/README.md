# Site

A terraform module for creating a simple static site that's stored on S3 and served by CloudFront. This can be achieved in many different ways in AWS, I wanted to achieve the following:

- It should serve `index.html` in the root  
  That is, `example.mads-hartmann.com` should serve `example.mads-hartmann.com/index.html`. CloudFront allows this by setting `default_root_object`.

- It should serve `index.html` in subdirectories  
  CloudFront doesn't support this out of the box as `default_root_object` only applies to the root. This has been achieved by associating a Lambda@Edge function with CloudFront distribution which does the request re-writing - this is the only way to achieve if you you want to keep the bucket contents truly private, more details below.

- It should serve `404.html` when requesting a resource that doesn't exist  
  This has been achieved by using a [Custom Error Response](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/GeneratingCustomErrorResponses.html) which turns 403's from S3 into 404's and serves the `404.html` page.

- The S3 bucket should __only__ be reachable through CloudFront  
  The bucket is private, the CloudFront distribution has been configured to use a [Origin Access Identity (OAI)](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html) which has been grated read-only access to the bucket. Additionally, the bucket has been configured with [Amazon S3 Block Public Access](https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html) so that the bucket or objects in it can't ever be made public.

- TODO: It should have basic DOS prevention (achieved by associating a WAF with CF)
- TODO: It should be possible to get viewing statistics
- TODO: Cost calculator for the site

This will create the following resources:

- A private S3 bucket for hosting the static files
    - An Origin Access Identity (OAI) to give CloudFront access to the S3 bucket.
- A CloudFront distribution for serving and caching the contents in s3
    - Lambda@edge function to serve index.html for subdirectories
- Alias record for domain
- WAF

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
