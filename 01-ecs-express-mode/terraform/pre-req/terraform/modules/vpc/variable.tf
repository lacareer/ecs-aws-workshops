variable "vpc_tags" {
  description = "A map of tags to apply to the VPC."
  type        = map(string)
  default = {
    Environment = "dev"
    Owner       = "networking"
  }
}

variable "vpc_name" {
  description = "Name of the VPC."
  type        = string
}

variable "networking_config" {
  description = "Networking configuration for the VPC"
  type = object({
    vpc_a_cidr        = string
    subnet_count      = number
    vpc_a_pub_subnet  = list(string)
    vpc_a_priv_subnet = list(string)
    dns_support       = bool
    hostname_support  = bool
    tenancy           = string
  })

  default = {
    vpc_a_cidr        = "10.0.0.0/16"
    subnet_count      = 2
    vpc_a_pub_subnet  = ["10.0.0.0/24", "10.0.2.0/24"]
    vpc_a_priv_subnet = ["10.0.1.0/24", "10.0.3.0/24"]
    dns_support       = true
    hostname_support  = true
    tenancy           = "default"
  }
}
