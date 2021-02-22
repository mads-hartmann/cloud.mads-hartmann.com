variable "name" {
  type        = string
  description = "The name of the API"
}

variable "s3_key" {
  type = string
  description = "The S3 objet key to use for the the lambda function"
}
