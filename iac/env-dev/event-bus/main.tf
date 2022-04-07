
locals {
  description = "created by terraform module github.com/dirt-simple/terraform-aws-s3-event-bus"
  name        = "dirt-simple-s3-event-bus"
}

data "aws_caller_identity" "current" {}

// Create a Test Bucket
resource "aws_s3_bucket" "event_test" {
  bucket = "dirt-simple-s3-event-bus-testing-${data.aws_caller_identity.current.account_id}"
  acl    = "private"
}

data "aws_lambda_function" "s3_event_bus" {
  function_name = "dirt-simple-s3-event-bus"
}

resource "aws_s3_bucket_notification" "s3_event_bus" {
  bucket = aws_s3_bucket.event_test.id
  lambda_function {
    id                  = aws_s3_bucket.event_test.id
    lambda_function_arn = data.aws_lambda_function.s3_event_bus.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowBucket-${aws_s3_bucket.event_test.id}"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.s3_event_bus.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.event_test.id}"
}

##################

resource "aws_sns_topic" "event_bus_topic" {
  name = local.name
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = local.name
  description        = local.description
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.event_bus_topic.arn]
  }
}

resource "aws_iam_role_policy" "lambda" {
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_lambda_function" "lambda" {
  function_name                  = local.name
  filename                       = data.archive_file.lambda.output_path
  source_code_hash               = data.archive_file.lambda.output_base64sha256
  role                           = aws_iam_role.lambda.arn
  runtime                        = "python3.6"
  handler                        = "index.handler"
  memory_size                    = 128
  reserved_concurrent_executions = 15
  publish                        = true
  description                    = local.description

  environment {
    variables = {
      S3_EVENT_BUS_TOPIC_ARN = aws_sns_topic.event_bus_topic.arn
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 90
}

output "s3_event_bus_topic_arn" {
  value = aws_sns_topic.event_bus_topic.arn
}

output "s3_event_bus_topic_name" {
  value = aws_sns_topic.event_bus_topic.name
}
