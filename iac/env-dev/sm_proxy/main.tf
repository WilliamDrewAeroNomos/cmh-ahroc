#------------------------------------------------------------
# IAM
#------------------------------------------------------------

resource "aws_iam_role" "lambda_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_policy" "lambda_policy" {
  policy = data.aws_iam_policy_document.lambda_policy_document.json
}

data "aws_iam_policy_document" "lambda_policy_document" {
  statement {
    sid       = "AllowSQSPermissions"
    effect    = "Allow"
    resources = ["arn:aws:sqs:*"]

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
  }

  statement {
    sid       = "AllowInvokingLambdas"
    effect    = "Allow"
    resources = ["arn:aws:lambda:${var.AWS_REGION}:*:function:*"]
    actions   = ["lambda:InvokeFunction"]
  }

  statement {
    sid       = "AllowCreatingLogGroups"
    effect    = "Allow"
    resources = ["arn:aws:logs:${var.AWS_REGION}:*:*"]
    actions   = ["logs:CreateLogGroup"]
  }
  statement {
    sid       = "AllowWritingLogs"
    effect    = "Allow"
    resources = ["arn:aws:logs:${var.AWS_REGION}:*:log-group:/aws/lambda/*:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

#------------------------------------------------------------
# Lambda
#------------------------------------------------------------

data "archive_file" "state_machine_trigger_lambda" {
  type        = "zip"
  source_file = "${path.module}/state_machine_trigger_lambda.js"
  output_path = "${path.module}/state_machine_trigger_lambda.js.zip"
}

resource "aws_lambda_function" "state_machine_trigger_lambda" {
  function_name = "state_machine_trigger_lambda"
  handler       = "state_machine_trigger_lambda.handler"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs14.x"

  filename         = data.archive_file.state_machine_trigger_lambda.output_path
  source_code_hash = data.archive_file.state_machine_trigger_lambda.output_base64sha256

  timeout     = 30
  memory_size = 128
}

#------------------------------------------------------------
# SQS
#------------------------------------------------------------

resource "aws_sqs_queue" "sm_trigger_queue" {
  name = "Lambda_State_Machine_Trigger"
}

#------------------------------------------------------------
# Event to source mapping
#------------------------------------------------------------

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  batch_size       = 1
  event_source_arn = aws_sqs_queue.sm_trigger_queue.arn
  enabled          = true
  function_name    = aws_lambda_function.state_machine_trigger_lambda.arn
}


