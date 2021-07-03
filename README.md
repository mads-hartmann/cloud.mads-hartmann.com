# cloud.mads-hartmann.com

How I manage my cloud resources for my own personal sites. As well as a few different experiments to better understand how various bits and pieces work in practice.

## Terraform

To run terraform:

```sh
cd terraform/production
terraform validate
terraform init
terraform plan
```

How to upload and invalidate the CloudFront cache for the example site.

```sh
./scripts/deploy-example-site.sh
```

### Initial setup

- Manually created the s3 bucket for storing the terraform state with bucket versioning enabled
