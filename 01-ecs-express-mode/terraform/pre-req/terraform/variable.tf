variable "profile" {
  description = "AWS CLI profile to use."
  default     = "my-sandbox"
  type        = string
}

variable "region" {
  description = "AWS region to use."
  default     = "us-east-1"
  type        = string
}

variable "config_tags" {
  description = "A map of tags to apply to resources."
  type        = map(string)
  default = {
    Environment = "dev"
    Owner       = "Network Team"
    company     = "chukky.com"
  }
}

##NEW CODE
variable "vpcs" {
  description = "Map of VPCs to create"
  type = map(object({
    networking_config = object({
      vpc_cidr         = string
      subnet_count     = number
      pub_subnets      = list(string)
      priv_subnets     = list(string)
      dns_support      = bool
      hostname_support = bool
      tenancy          = string
    })
  }))
}