terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.74.3"
    }
  }
}

provider "aws" {
  region = var.AWS_REGION

  default_tags {
    tags = {
      Environment                    = "${var.ENVIRONMENT}",
      "Impact Level"                 = "${var.IMPACT_LEVEL}",
      Organization                   = "${var.ORGANIZATION}",
      "Cost Center"                  = "${var.COST_CENTER}",
      "Core Function Lead"           = "${var.CORE_FUNCTION_LEAD}",
      "Cost Allocation"              = "${var.COST_ALLOCATION}",
      "Contact-Government Primary"   = "${var.CONTACT_GOVERNMENT_PRIMARY}",
      "Contact-Government Secondary" = "${var.CONTACT_GOVERNMENT_SECONDARY}",
      Contact-Other                  = "${var.CONTACT_OTHER}",
      APMS                           = "${var.APMS}",
      EMASS                          = "${var.EMASS}",
      "System Name"                  = "${var.SYSTEM_NAME}",
      Enterprise                     = "${var.ENTERPRISE}",
      "Public Facing"                = "${var.PUBLIC_FACING}",
      "Initial Support Provider"     = "${var.INITIAL_SUPPORT_PROVIDER}",
      AutoShutdownSchedule           = "${var.AUTO_SHUTDOWN_SCHEDULE}"
    }
  }
}

provider "aws" {
  region = var.AWS_REGION

  alias = "S3-bucket-object-tags"

  default_tags {
    tags = {
      Environment                  = "${var.ENVIRONMENT}",
      "Impact Level"               = "${var.IMPACT_LEVEL}",
      Organization                 = "${var.ORGANIZATION}",
      "Cost Center"                = "${var.COST_CENTER}",
      "Cost Allocation"            = "${var.COST_ALLOCATION}",
      "Contact-Government Primary" = "${var.CONTACT_GOVERNMENT_PRIMARY}"
    }
  }
}

