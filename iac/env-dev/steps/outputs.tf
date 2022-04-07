
# Outputs

output "random-number-generator-function-arn" {
  value = aws_lambda_function.random-number-generator-lambda.arn
}

output "power-of-number-lambda-function-arn" {
  value = aws_lambda_function.power-of-number-lambda.arn
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.sfn_state_machine.arn
}
