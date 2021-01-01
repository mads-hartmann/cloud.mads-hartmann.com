variable "domain" {
  type        = string
  description = "The fully qualified domain name"
}

variable "acm_certificate_arn" {
  type        = string
  description = "The ARN of the ACM managed SSL certificate to use"
}
