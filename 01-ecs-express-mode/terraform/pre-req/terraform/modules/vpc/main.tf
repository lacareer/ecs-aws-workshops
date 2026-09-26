locals {
  vpc_network_info = var.networking_config
  vpc_tags         = var.vpc_tags
}


data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Vpc resource
resource "aws_vpc" "vpc" {
  cidr_block = local.vpc_network_info.vpc_a_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags       = local.vpc_tags
}

# Public Subnet Resources with internet access
resource "aws_subnet" "public_subnets" {
  count                   = local.vpc_network_info.subnet_count
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  cidr_block              = local.vpc_network_info.vpc_a_pub_subnet[count.index]
  tags                    = merge(local.vpc_tags, { Name = "${var.vpc_name}_pub_subnet-${count.index + 1}" })
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.vpc_tags, { Name = "${var.vpc_name}_public_route_table" })
}

resource "aws_route_table_association" "public_route_table_association" {
  count          = local.vpc_network_info.subnet_count
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# internet gateway resource for public subnets
resource "aws_internet_gateway" "public_subnet_igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.vpc_tags, { Name = "${var.vpc_name}_public_subnet_igw" })
}

resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public_subnet_igw.id
}

# Private Subnet Resources with no internet access
resource "aws_subnet" "private_subnets" {
  count                   = local.vpc_network_info.subnet_count
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  cidr_block              = local.vpc_network_info.vpc_a_priv_subnet[count.index]
  tags                    = merge(local.vpc_tags, { Name = "${var.vpc_name}_priv_subnet-${count.index + 1}" })
}

# needed to created multiple private route tables for each private subnet to connect to the internet via NAT Gateway
resource "aws_route_table" "private_route_table" {
  count  = local.vpc_network_info.subnet_count
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.vpc_tags, { Name = "${var.vpc_name}_private_route_table-${count.index + 1}" })
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = local.vpc_network_info.subnet_count
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

# Private connection from private to public subnets using NAT Gateway
resource "aws_eip" "nat_eip" {
  count  = local.vpc_network_info.subnet_count
  domain = "vpc"
  tags   = merge(local.vpc_tags, { Name = "${var.vpc_name}_nat_eip-${count.index + 1}" })
}

resource "aws_nat_gateway" "private_subnet_nat_gateway" {
  count         = local.vpc_network_info.subnet_count
  allocation_id = aws_eip.nat_eip[count.index].id

  subnet_id     = aws_subnet.public_subnets[count.index].id

  tags = merge(local.vpc_tags, { Name = "${var.vpc_name}_priv_subnet-${count.index + 1}-ngw" })
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.public_subnet_igw]
}

resource "aws_route" "private_internet_route" {
  count                  = local.vpc_network_info.subnet_count
  route_table_id         = aws_route_table.private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.private_subnet_nat_gateway[count.index].id
}

# NACL Resources. Not that egress=false for ingress and egress=true for egress rules. 
# NACLs are stateless, so you need to create both ingress and egress rules for traffic to flow in both directions.
resource "aws_network_acl" "vpc_acl" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.vpc_tags, { Name = "${var.vpc_name}_acl" })
}

# NACL Resources. Note that for ingress egress=false (should not be added as shown below) and for egress egress=true.
# only add egress=true to prevent outbound traffic to the internet. In which case any rule with egress=false will be ignored.
# NACLs are stateless, so you need to create both ingress and egress rules for traffic to flow in both directions.

resource "aws_network_acl_rule" "igress_rule" {
  network_acl_id = aws_network_acl.vpc_acl.id
  rule_number    = 100
  protocol       = "-1"
  # egress         = false #do not add for ingress rules, as it will be ignored. Only add egress=true for egress rules.
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "Egress_rule" {
  network_acl_id = aws_network_acl.vpc_acl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_association" "public_subnets" {
  count          = local.vpc_network_info.subnet_count
  network_acl_id = aws_network_acl.vpc_acl.id
  subnet_id      = aws_subnet.public_subnets[count.index].id
}

resource "aws_network_acl_association" "private_subnets" {
  count          = local.vpc_network_info.subnet_count
  network_acl_id = aws_network_acl.vpc_acl.id
  subnet_id      = aws_subnet.private_subnets[count.index].id
}

# ─── VPC Endpoints ──
# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private_route_table[*].id
  tags              = merge(local.vpc_tags, { Name = "${var.vpc_name}_s3_endpoint" })
}

# KMS Interface Endpoint
resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_subnets[*].id
  tags                = merge(local.vpc_tags, { Name = "${var.vpc_name}_kms_endpoint" })
}