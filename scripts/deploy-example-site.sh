#!/usr/bin/env bash

set -euo pipefail

export AWS_PROFILE=mads-personal

# Read relevant output variables
AWS_ACCESS_KEY_ID=$(terraform -chdir=terraform/production output -raw example-mads-hartmann-com-deploy-access-key-id)
AWS_SECRET_ACCESS_KEY=$(terraform -chdir=terraform/production output -raw example-mads-hartmann-com-deploy-access-key-secret)
CLOUDFRONT_DISTRIBUTION_ID="$(terraform -chdir=terraform/production output -raw example-mads-hartmann-com-distribution-id)"

# Use the credentials for the example.mads-hartmann.com site
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

# Upload files
aws s3 sync \
    --region us-east-1 \
    examples/site/ s3://example.mads-hartmann.com/

# Invalidate the cache
aws cloudfront create-invalidation \
    --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
    --paths '/*'
