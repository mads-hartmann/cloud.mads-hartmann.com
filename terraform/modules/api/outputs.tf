output "endpoint" {
  value       = aws_apigatewayv2_api.api.api_endpoint
  description = "The endpoint of the API Gateway"
}
