
data "aws_caller_identity" "current" {}

locals {
  prefix              = "ahroc"
  app_dir             = "apps"
  account_id          = data.aws_caller_identity.current.account_id
  ecr_repository_name = "${local.prefix}-lambda-container"
  ecr_image_tag       = "latest"
}

resource "aws_ecr_repository" "repo" {
  name = local.ecr_repository_name
}

# The null_resource resource implements the standard resource lifecycle 
# but takes no further action.

# The triggers argument allows specifying an arbitrary set of values that, 
# when changed, will cause the resource to be replaced.

resource "null_resource" "ecr_image" {
  triggers = {
    python_file = md5(file("${path.module}/${local.app_dir}/hours.py"))
    docker_file = md5(file("${path.module}/${local.app_dir}/Dockerfile"))
  }

  # The local-exec provisioner invokes a local executable after a resource is created. 
  # This invokes a process on the machine running Terraform, not on the resource. 
  # path.module: the filesystem path of the module where the expression is placed.

  provisioner "local-exec" {
    command = <<EOF
           aws ecr get-login-password --region ${var.AWS_REGION} | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com
           cd ${path.module}/${local.app_dir}
           docker build -t ${aws_ecr_repository.repo.repository_url}:${local.ecr_image_tag} .
           docker push ${aws_ecr_repository.repo.repository_url}:${local.ecr_image_tag}
       EOF
  }
}

data "aws_ecr_image" "ecr_image" {
  depends_on = [
    null_resource.ecr_image
  ]
  repository_name = local.ecr_repository_name
  image_tag       = local.ecr_image_tag
}

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

resource "aws_iam_role" "iam_role" {
  name               = "${local.prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_lambda_function" "lambda_function" {
  depends_on = [
    null_resource.ecr_image
  ]
  function_name = "${local.prefix}-lambda"
  role          = aws_iam_role.iam_role.arn
  timeout       = 300
  image_uri     = "${aws_ecr_repository.repo.repository_url}@${data.aws_ecr_image.ecr_image.id}"
  package_type  = "Image"
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}


output "lambda_name" {
  value = aws_lambda_function.lambda_function.id
}

