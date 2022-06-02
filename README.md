# Simple terraform IaC for AWS Lambda

While playing around with Terraform, I realised how hard it is to find a simple working example for spinning up a Lambda function triggered by SQS messages.
As a way to consolidate my learnings, I decided to write this small [blog post](https://www.craft.do/s/0bCnXUlirJtuQr).

This repository contains reference code for that post.

## Usage

Create an AWS profile named `terraform_test`, deploy the infra with:

```
terraform init
terraform apply
```

Destroy with

```
terraform destroy
```
