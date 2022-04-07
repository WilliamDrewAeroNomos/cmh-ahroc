
terraform {
  backend "s3" {
    bucket         = "dod-usarmy-tradoc-cmh-arhoc-terraform-state"
    key            = "ahroc/dev/persistence/mongodb/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dod-usarmy-tradoc-cmh-arhoc-terraform-state-locks"
    encrypt        = true
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "dod-usarmy-tradoc-cmh-arhoc-terraform-state"
    key    = "ahroc/dev/network/terraform.tfstate"
    region = "us-east-1"
  }
}
