locals {
  config_tags = var.config_tags
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# ─── VPCs ────────────────────────────────────────────────────────────────────
module "vpc" {
  for_each = var.vpcs
  source   = "./modules/vpc"
  vpc_name = each.key
  networking_config = {
    vpc_a_cidr        = each.value.networking_config.vpc_cidr
    subnet_count      = each.value.networking_config.subnet_count
    vpc_a_pub_subnet  = each.value.networking_config.pub_subnets
    vpc_a_priv_subnet = each.value.networking_config.priv_subnets
    dns_support       = each.value.networking_config.dns_support
    hostname_support  = each.value.networking_config.hostname_support
    tenancy           = each.value.networking_config.tenancy
  }
  vpc_tags = merge(local.config_tags, { Name = each.key })
}

