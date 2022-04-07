
#------------------------------------------------------
# Create archive file from sources
#------------------------------------------------------

data "archive_file" "zip_files" {
  for_each = var.lambdas
  type     = "zip"

  source_dir  = "${path.module}/apps/${each.value.path}"
  output_path = "${path.module}/${each.value.path}.zip"
}

#------------------------------------------------------
# Create basic lambda execution role 
#------------------------------------------------------

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_basic_execution_role" {
  name = "lambda_basic_execution_role"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

#resource "aws_iam_role" "lambda_basic_execution_role" {
#  name = "ahroc_lambda"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [{
#      Action = "sts:AssumeRole"
#      Effect = "Allow"
#      Sid    = ""
#      Principal = {
#        Service = "lambda.amazonaws.com"
#      }
#      }
#    ]
#  })
#}

#------------------------------------------------------
# Attach policy to lambda execution role 
#------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_policy" {
  role       = aws_iam_role.lambda_basic_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda_functions" {
  for_each         = var.lambdas
  filename         = data.archive_file.zip_files[each.key].output_path
  function_name    = each.value.name
  role             = aws_iam_role.lambda_basic_execution_role.arn
  handler          = "${each.value.path}.handler"
  source_code_hash = data.archive_file.zip_files[each.key].output_base64sha256

  runtime = "nodejs14.x"
}

resource "aws_lambda_permission" "apigw" {
  for_each      = aws_lambda_function.lambda_functions
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}


#------------------------------------------------------
# Create the API gateway 
#------------------------------------------------------

resource "aws_api_gateway_rest_api" "api_gateway" {
  name = var.api-gateway-name
  description = "Multi-lambda deployment"
}

#------------------------------------------------------
# Iterate over var.lambdas and set path 
#------------------------------------------------------

resource "aws_api_gateway_resource" "resources" {
  for_each    = var.lambdas
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = each.value.path
}

#------------------------------------------------------
# Resource IDs and methods for each aws_api_gateway_resource
#------------------------------------------------------

resource "aws_api_gateway_method" "methods" {
  for_each         = aws_api_gateway_resource.resources
  rest_api_id      = aws_api_gateway_rest_api.api_gateway.id
  resource_id      = each.value.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}


resource "aws_api_gateway_method_response" "response_200" {
  for_each    = aws_api_gateway_method.methods
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id

  resource_id = each.value.resource_id
  http_method = each.value.http_method
  status_code = "200"

  response_models = { "application/json" = "Empty" }
}

#------------------------------------------------------
# Attach or integrate each lambda function to the API gateway
#------------------------------------------------------

resource "aws_api_gateway_integration" "integration" {
  for_each                = aws_api_gateway_method.methods
  rest_api_id             = each.value.rest_api_id
  resource_id             = each.value.resource_id
  http_method             = each.value.http_method
  integration_http_method = each.value.http_method
  type                    = "AWS"
  uri                     = aws_lambda_function.lambda_functions[each.key].invoke_arn
}


resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  depends_on = [
    aws_api_gateway_integration.integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = var.ENVIRONMENT
}

output "base_url" {
  value = aws_api_gateway_deployment.api_gateway_deployment.invoke_url
}
#output "private_subnet_ids" {
#  value = aws_subnet.private_subnets.*.id
#}

