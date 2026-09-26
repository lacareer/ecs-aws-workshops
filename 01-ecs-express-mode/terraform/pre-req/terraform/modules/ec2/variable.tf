variable "environment" {
  description = "The environment for the EC2 instance."
  type        = string
  default     = "AWS"
}

variable "vpc_id" {
  description = "The ID of the VPC where the EC2 instance will be launched."
  type        = string
}

variable "vpc_cidr_range" {
  description = "The CIDR range of the VPC where the EC2 instance will be launched."
  type        = string
}

variable "ec2_tags" {
  description = "A map of tags to apply to the EC2."
  type        = map(string)
  default = {
    Environment = "dev"
    Owner       = "networking"
  }
}

variable "ec2_sg_name" {
  description = "The name of the EC2 security group."
  type        = string
  default     = "ec2_security_group"
}

variable "ec2_data" {
  description = "Data for the EC2 instance including private IP address and instance size"
  type = object({
    public         = map(string)
    private        = map(string)
    classification = list(string)
  })
  default = {
    classification = ["public", "private"]
    public         = { name = "ec2_instance_public", default = "10.0.2.100", ec2_instance_size = "t2.micro" },
    private        = { name = "ec2_instance_private", default = "10.0.1.100", ec2_instance_size = "t2.micro" }
  }
}

variable "ec2_ingress" {
  description = "List of ingress ports for the EC2 instance"
  type = object({
    cidr      = string
    type      = string
    to_port   = number
    from_port = number
    protocol  = string
  })
}

variable "ec2_egress" {
  description = "List of egress ports for the EC2 instance"
  type = object({
    cidr      = string
    type      = string
    to_port   = number
    from_port = number
    protocol  = string
  })
}

variable "ec2_instance_profile" {
  description = "EC2 instance profile"
  type        = string
  default     = "NetworkingWorkshopInstanceProfile"
}

variable "subnet_id" {
  description = "The ID of the subnet where the EC2 instance will be launched."
  type        = string
}