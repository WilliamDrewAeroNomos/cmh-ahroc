variable "AWS_REGION" {
  description = "Default region"
  type        = string
  default     = "us-east-1"
}

variable "IMPACT_LEVEL" {
  description = "Security impact level - IL1 - IL6"
  type        = string
  default     = "IL4"
}

variable "ORGANIZATION" {
  description = "Organization"
  type        = string
  default     = "TRADOC CMH AWS"
}

variable "COST_CENTER" {
  description = "Organization"
  type        = string
  default     = "HMH : Center of Military History - CMH"
}

variable "CORE_FUNCTION_LEAD" {
  description = "Core function lead "
  type        = string
  default     = "CMH : U.S. Army Center of Military History"
}

variable "COST_ALLOCATION" {
  description = "Cost allocation"
  type        = number
  default     = 100
}

variable "CONTACT_GOVERNMENT_PRIMARY" {
  description = "Primary government contact"
  type        = string
  default     = "colleen.m.apte.civ@mail.mil"
}

variable "CONTACT_GOVERNMENT_SECONDARY" {
  description = "Secondary government contact"
  type        = string
  default     = "empty"
}

variable "CONTACT_OTHER" {
  description = "Additional contact"
  type        = string
  default     = "empty"
}

variable "APMS" {
  description = "APMS"
  type        = string
  default     = "DA309787"
}

variable "EMASS" {
  description = "EMASS"
  type        = number
  default     = 377
}

variable "SYSTEM_NAME" {
  description = "System name"
  type        = string
  default     = "AHRO-C"
}

variable "ENTERPRISE" {
  description = "Does this application impact the enterprise?"
  type        = string
  default     = "YES"
}

variable "PUBLIC_FACING" {
  description = "Is this application have a public face/access?"
  type        = string
  default     = "YES"
}

variable "INITIAL_SUPPORT_PROVIDER" {
  description = "Initial support provider"
  type        = string
  default     = "empty"
}

variable "AUTO_SHUTDOWN_SCHEDULE" {
  description = "Initial support provider"
  type        = string
  default     = "0000-1200 UTC"
}


variable "resource_name" {
  default = "number"
}

# Network

variable "VPC_NAME" {
  description = "Working context (i.e. - dev, test, pre-prod)"
  type        = string
}

variable "CIDR_BLOCK" {
  description = "Working context (i.e. - dev, test, pre-prod)"
  type        = string
}

variable "ENVIRONMENT" {
  description = "Working context (i.e. - dev, test, pre-prod)"
  type        = string
}

variable "PATH_TO_PRIVATE_KEY" {
  default = "ahroc-front-end-key"
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "ahroc-front-end-key.pub"
}

variable "lambdas" {
  description = "Map of Lambda function names and API gateway resource paths."
  type        = map(any)
  default = {
    users = {
      name    = "users-lambda"
      path    = "users"
      handler = "users.handler"
    },
    products = {
      name    = "products-lambda"
      path    = "products"
      handler = "products.handler"
    },
    orders = {
      name    = "orders-lambda"
      path    = "orders"
      handler = "orders.handler"
    }
  }
}

variable "api-gateway-name" {
  default = "ahroc_lambda_api_gw"
}
variable "lambda_function_name" {
  default = "hello_world"
}
variable "lambda_name" {
  default = "hello_world_lambda"
}

variable "phone_number_for_notification" {
  type        = string
  description = "Valid mobile number for notification"
  default     = "(301) 523-1817"
}



# Persistence
variable "vpc_name" {
  type = string
}
variable "domain" {
  type = string
}
variable "instance_type" {
  type = string
}
variable "tag_domain" {
  type = string
}
variable "volume_type" {
  type = string
}
variable "ebs_volume_size" {}

variable "replica_set_name" {
}

variable "num_secondary_nodes" {
}

variable "mongo_password" {
}

variable "mongo_username" {
}

variable "mongo_database" {
}

variable "primary_node_type" {
}

variable "secondary_node_type" {
}

variable "key_name" {
  type = string
}


