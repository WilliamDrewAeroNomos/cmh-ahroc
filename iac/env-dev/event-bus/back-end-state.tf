
# ----------------------------------------------
# Back end configuration stored in S3 bucket
# Note: "terraform.backend.key must match
#       the environment (i.e. dev, test, 
#			  stage, etc.) and the layer (application,
#				persistence, network, etc.)
# ----------------------------------------------

terraform {
  backend "s3" {
    bucket         = "dod-usarmy-tradoc-cmh-arhoc-terraform-state"
    key            = "ahroc/dev/event-bus/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dod-usarmy-tradoc-cmh-arhoc-terraform-state-locks"
    encrypt        = true
  }
}

data "terraform_remote_state" "steps" {
  backend = "s3"
  config = {
    bucket = "dod-usarmy-tradoc-cmh-arhoc-terraform-state"
    key    = "ahroc/dev/steps/terraform.tfstate"
    region = "us-east-1"
  }
}
