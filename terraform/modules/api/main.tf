locals {

  # Some attributes can't have . in the name, so in those cases we'll use this instead. Example:
  hyphened_name = replace(var.name, ".", "-")

  # Common tags to apply to resources - useful for grouping expenses in the cost explorer.
  tags = {
    Name    = var.name
    Project = var.name
  }
}

#
# API Gateway v2
#

resource "aws_apigatewayv2_api" "api" {
  name          = "${local.hyphened_name}-http-api"
  description   = "API for ${local.hyphened_name}"
  protocol_type = "HTTP"

  tags = local.tags

  target = aws_lambda_function.lambda.arn

  # TODO:
  # - Set cors?
  # - Set timeout?

}

#
# Lambda
#

# An S3 bucket for storing the lambda versions
resource "aws_s3_bucket" "bucket" {
  bucket = local.hyphened_name
  acl    = "private"

  tags = local.tags

  # TODO: Decide if I want versioning
  versioning {
    enabled = false
  }
}

# Give APIGateway permission to invoke the lambda function
resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke-${local.hyphened_name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # THe /*/* Allows invocation from any stage and any route
  # within API Gateway HTTP API.
  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Create an IAM role and grant Lambda the permission to assume the role.
resource "aws_iam_role" "lambda" {
  name        = "${local.hyphened_name}-lambda-role"
  description = "Role for ${local.hyphened_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  tags = local.tags
}

resource "aws_lambda_function" "lambda" {

  s3_bucket = aws_s3_bucket.bucket.id
  s3_key    = var.s3_key


  function_name = local.hyphened_name
  handler       = "index.handler"

  # The role we want to Lambda to assume (its execution role)
  role = aws_iam_role.lambda.arn

  # No need for versioning
  publish = false

  runtime = "nodejs12.x"

  tags = local.tags
}
