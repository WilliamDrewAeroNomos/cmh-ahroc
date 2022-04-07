#-----------------------------
# Output value definitions
#-----------------------------

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.lambda.invoke_url
}

output "function_name" {
  description = "Lambda name"
  value       = aws_lambda_function.hello_world.function_name
}
