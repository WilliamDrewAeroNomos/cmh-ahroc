resource "random_pet" "server" {
}

data "aws_iam_policy_document" "allow_state_machine_exec" {
  statement {
  	effect  = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = ["states.amazonaws.com", "apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "allow_state_machine_exec" {
  name               = "AWS_Events_Invoke-StepFunc"
  assume_role_policy = data.aws_iam_policy_document.allow_state_machine_exec.json
}

resource "aws_iam_role_policy" "state-execution" {
  name   = "CW2SF_allowexec"
  role   = aws_iam_role.allow_state_machine_exec.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "states:StartExecution"
            ],
            "Resource": "arn:aws:states:us-east-1:206378228634:stateMachine:sample-state-machine"
        }
    ]
}
EOF

}


# var.aws_region = eu-central-1
# var.sfn_orchestrater_arn = arn:aws:states:eu-central-1:*account*:stateMachine:*step-function-entry-point*

#------------------------------------------------------
# Create the API gateway 
#------------------------------------------------------

resource "aws_api_gateway_rest_api" "this" {
  name        = "Lambda API Gateway - Prototype Start SM Execution"
  description = "Prototyping starting SM via API GM"
}


resource "aws_api_gateway_resource" "number" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "${var.resource_name}"
}

resource "aws_api_gateway_method" "number" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.number.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "endpoint_integration" {
  credentials             = aws_iam_role.allow_state_machine_exec.arn
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_method.number.resource_id
  http_method             = aws_api_gateway_method.number.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  uri                     = "arn:aws:apigateway:us-east-1:states:action/StartExecution"

  request_templates = {
    "application/json" = <<EOF
{
    "input": "$util.escapeJavaScript($input.json('$'))",
    "name" " "KankakeeIllinois1959"
    "stateMachineArn": "arn:aws:states:us-east-1:206378228634:stateMachine:sample-state-machine"
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
    aws_api_gateway_integration.endpoint_integration
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
    aws_api_gateway_integration.endpoint_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = var.ENVIRONMENT
}
output "base_url" {
  value = "${aws_api_gateway_deployment.api_gateway_deployment.invoke_url}/${var.resource_name}"
}

