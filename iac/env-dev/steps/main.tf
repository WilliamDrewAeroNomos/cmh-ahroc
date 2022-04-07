

#------------------------------------------------------
# Create IAM role for AWS Step Function
#------------------------------------------------------
resource "aws_iam_role" "iam_for_sfn" {
  name = "stepFunctionExecutionIAMRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

#------------------------------------------------------
# Create policy to publish to SMS
#------------------------------------------------------
resource "aws_iam_policy" "policy_publish_sms" {
  name = "stepFunctionSNSPublishPolicy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
              "sns:Publish",
              "sns:SetSMSAttributes",
              "sns:GetSMSAttributes"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
// Create archives for AWS Lambda functions which will be used for Step Function

data "archive_file" "archive-power-of-number-lambda" {
  type        = "zip"
  output_path = "power-of-number-lambda/archive.zip"
  source_file = "power-of-number-lambda/index.js"
}

data "archive_file" "archive-random-number-generator-lambda" {
  type        = "zip"
  output_path = "random-number-generator-lambda/archive.zip"
  source_file = "random-number-generator-lambda/index.js"
}

#------------------------------------------------------
# Create policy to invoke Lambda function
#------------------------------------------------------
resource "aws_iam_policy" "policy_invoke_lambda" {
  name = "stepFunctionLambdaInvocationPolicy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction",
                "lambda:InvokeAsync"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#------------------------------------------------------
#  Attach policy for invoking functions to IAM Role
#------------------------------------------------------

resource "aws_iam_role_policy_attachment" "iam_for_sfn_attach_policy_invoke_lambda" {
  role       = aws_iam_role.iam_for_sfn.name
  policy_arn = aws_iam_policy.policy_invoke_lambda.arn
}

#------------------------------------------------------
#  Attach policy for publishing to SMS to IAM Role
#------------------------------------------------------
 
resource "aws_iam_role_policy_attachment" "iam_for_sfn_attach_policy_publish_sns" {
  role       = aws_iam_role.iam_for_sfn.name
  policy_arn = aws_iam_policy.policy_publish_sms.arn
}

// Create AWS Lambda functions

resource "aws_lambda_function" "power-of-number-lambda" {
  filename      = data.archive_file.archive-power-of-number-lambda.output_path
  function_name = "step-functions-sample-power-of-number"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
}

resource "aws_lambda_function" "random-number-generator-lambda" {
  filename      = data.archive_file.archive-random-number-generator-lambda.output_path
  function_name = "step-functions-sample-random-number-generator"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
}

// Create IAM role for AWS Lambda

resource "aws_iam_role" "iam_for_lambda" {
  name = "stepFunctionSampleLambdaIAM"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#------------------------------------------------------
# Create state machine using lambdas
#------------------------------------------------------

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "sample-state-machine"
  role_arn = aws_iam_role.iam_for_sfn.arn

  definition = <<EOF

{
  "StartAt": "random-number-generator-lambda-config",
  "States": {


    "random-number-generator-lambda-config": {
      "Comment": "To configure the random-number-generator-lambda.",
      "Type": "Pass",
      "Result": {
          "min": 1,
          "max": 10
        },
      "ResultPath": "$",
      "Next": "random-number-generator-lambda"
    },


    "random-number-generator-lambda": {
      "Comment": "Generate a number based on input.",
      "Type": "Task",
      "Resource": "${aws_lambda_function.random-number-generator-lambda.arn}",
      "Next": "send-notification-if-less-than-5"
    },


    "send-notification-if-less-than-5": {
      "Comment": "A choice state to decide to send out notification for <5 or trigger power of three lambda for >5.",
      "Type": "Choice",
      "Choices": [
        {
            "Variable": "$",
            "NumericGreaterThanEquals": 5,
            "Next": "power-of-three-lambda"
        },
        {
          "Variable": "$",
          "NumericLessThan": 5,
          "Next": "send-multiple-notification"
        }
      ]
    },


    "power-of-three-lambda": {
      "Comment": "Increase the input to power of 3 with customized input.",
      "Type": "Task",
      "Parameters" : {
        "base.$": "$",
        "exponent": 3
      },
      "Resource": "${aws_lambda_function.power-of-number-lambda.arn}",
      "End": true
    },


    "send-multiple-notification": {
      "Comment": "Trigger multiple notification using AWS SMS",
      "Type": "Parallel",
      "End": true,
      "Branches": [
        {
         "StartAt": "send-sms-notification",
         "States": {
            "send-sms-notification": {
              "Type": "Task",
              "Resource": "arn:aws:states:::sns:publish",
              "Parameters": {
                "Message": "SMS: Random number is less than 5 $",
                "PhoneNumber": "${var.phone_number_for_notification}"
              },
              "End": true
            }
         }
       }
      ]
    }
  }
}
EOF

	#------------------------------------------------------
	# Set dependency on lambda creations
	#------------------------------------------------------
  depends_on = [aws_lambda_function.random-number-generator-lambda, 
  							aws_lambda_function.random-number-generator-lambda]

}

