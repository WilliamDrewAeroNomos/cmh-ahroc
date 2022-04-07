#---------------------------
# Test environment
#---------------------------

module "ahroc_main_vpc" {

  source = "git::https://github.com/WilliamDrewAeroNomos/tf-modules.git//modules/vpc?ref=v1.1"

  # insert required variables here

  _cidr_block = var.CIDR_BLOCK
  _name       = var.VPC_NAME

}
