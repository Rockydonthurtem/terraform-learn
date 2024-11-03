terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# variable "cidr_block" {
#   description = "cidr blocks and name tags for vpc and subnets"
#   type = list(object({
#     cidr_block = string
#     name       = string
#   }))
# }
