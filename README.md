# aws

## Examples

- examples/site is a simple static site

## Terraform

Various resources for personal projects.

```sh
cd terraform/production
AWS_PROFILE=mads-personal terraform init
AWS_PROFILE=mads-personal terraform plan
```

### Initial setup

- Manually created the s3 bucket for storing the terraform state with bucket versioning enabled
