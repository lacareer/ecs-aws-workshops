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

variable "cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service."
  type        = string
}

variable "container_image" {
  description = "Docker image for the ECS container."
  type        = string
}

variable "container_port" {
  description = "Port on which the ECS container listens."
  type        = number
}

variable "health_check_path" {
  description = "Path for the ECS container health check."
  type        = string
}

variable "cpu" {
  description = "CPU units for the ECS container."
  type        = number
}

variable "memory" {
  description = "Memory (in MiB) for the ECS container."
  type        = number
}

variable "ui_theme" {
  description = "UI theme for the frontend application."
  type        = string
}
# get the public subnet IDs from the VPC deployed using the console
variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ECS service."
  type        = list(string)
}

variable "environment" {
  description = "Environment variables for the ECS container."
  type        = map(string)
}
