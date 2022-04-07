
terraform {
  backend "s3" {
    bucket         = "dod-usarmy-tradoc-cmh-arhoc-terraform-state"
    key            = "ahroc/dev/lambdas/container/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dod-usarmy-tradoc-cmh-arhoc-terraform-state-locks"
    encrypt        = true
  }
}

