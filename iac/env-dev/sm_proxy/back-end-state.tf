
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
    key            = "ahroc/dev/sm_proxy/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dod-usarmy-tradoc-cmh-arhoc-terraform-state-locks"
    encrypt        = true
  }
}
