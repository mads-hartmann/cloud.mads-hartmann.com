# cloud.mads-hartmann.com

How I manage my cloud resources for my own personal sites. As well as a few different experiments to better understand how various bits and pieces work in practice.

## Examples

- examples/site is a simple static site

## Terraform

Various resources for personal projects.

```sh
cd terraform/production
AWS_PROFILE=mads-personal terraform init
AWS_PROFILE=mads-personal terraform plan
```

```sh
export AWS_ACCESS_KEY_ID='XXX'
export AWS_SECRET_ACCESS_KEY='YYY'
export CLOUDFRONT_DISTRIBUTION_ID="ZZZ"

# Upload files
aws s3 sync \
    --region us-east-1 \
    examples/site/ s3://example.mads-hartmann.com/

# Invalidate the cache
aws cloudfront create-invalidation \
    --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
    --paths '/*'
```

### Initial setup

- Manually created the s3 bucket for storing the terraform state with bucket versioning enabled
