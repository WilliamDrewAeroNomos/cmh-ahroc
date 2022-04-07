#------------------------------------------------------
# Create the API gateway 
#------------------------------------------------------

resource "aws_api_gateway_rest_api" "this" {
  name        = "Lambda API Gateway - Container"
  description = "Uses images from ECR created locally by Docker"
}

#------------------------------------------------------
# Create resource, set GW ID and path
#------------------------------------------------------

resource "aws_api_gateway_resource" "number" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "{${var.resource_name}+}"
}

resource "aws_api_gateway_method" "number" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.number.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api_gateway_integration" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_method.number.resource_id
  http_method = aws_api_gateway_method.number.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = <<EOF
{
  "hour" : $input.params('hour')
}
EOF
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  resource_id = aws_api_gateway_resource.number.id
  http_method = aws_api_gateway_method.number.http_method
  status_code = "200"

  response_models = { "application/json" = "Empty" }
}

resource "aws_api_gateway_integration_response" "integrationResponse" {
  depends_on = [
    aws_api_gateway_integration.api_gateway_integration,
  ]
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.number.id
  http_method = aws_api_gateway_method.number.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
  # Transforms the backend JSON response to json. The space is required!!
  response_templates = {
    "application/json" = <<EOF
 
 EOF
  }
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  depends_on = [
    aws_api_gateway_integration.api_gateway_integration,
    aws_api_gateway_integration_response.integrationResponse,
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = var.ENVIRONMENT
}

output "base_url" {
  value = "${aws_api_gateway_deployment.api_gateway_deployment.invoke_url}/${var.resource_name}"
}