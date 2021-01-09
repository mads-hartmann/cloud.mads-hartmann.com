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

### Initial setup

- Manually created the s3 bucket for storing the terraform state with bucket versioning enabled
