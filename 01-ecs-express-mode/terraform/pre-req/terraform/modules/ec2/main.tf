locals {
  instance_tags = var.ec2_tags
}


data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# ec2 instance resource and security groups
resource "aws_security_group" "allow_all_traffic" {
  name        = "${var.ec2_tags.Name}-sg"
  description = "Allow all inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id
  tags        = merge(local.instance_tags, { Name = "${var.ec2_tags.Name}-sg" })

}

resource "aws_security_group_rule" "allow_all_traffic_ingress" {
  type              = var.ec2_ingress.type
  from_port         = var.ec2_ingress.from_port
  to_port           = var.ec2_ingress.to_port
  protocol          = var.ec2_ingress.protocol
  security_group_id = aws_security_group.allow_all_traffic.id
  # cidr_blocks       = [var.ec2_ingress.cidr]

  cidr_blocks = [var.ec2_tags.Name == "private" ? var.vpc_cidr_range : var.ec2_ingress.cidr]

}

resource "aws_security_group_rule" "allow_all_traffic_egress" {
  type              = var.ec2_egress.type
  from_port         = var.ec2_egress.from_port
  to_port           = var.ec2_egress.to_port
  protocol          = var.ec2_egress.protocol
  cidr_blocks       = [var.ec2_egress.cidr]
  security_group_id = aws_security_group.allow_all_traffic.id
}


resource "aws_instance" "web" {
  iam_instance_profile        = var.ec2_instance_profile
  ami                         = nonsensitive(data.aws_ami.amazon_linux.id)
  instance_type               = var.ec2_data[var.ec2_tags.Name].ec2_instance_size
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.ec2_tags.Name == "public" ? true : false
  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/templates/ec2-user-data.tpl",
    {
      environment = var.environment,
      instance_name = var.ec2_tags.Name,
      instance_ip  = var.ec2_data[var.ec2_tags.Name].default
  })
  
  private_ip = var.ec2_data[var.ec2_tags.Name].default


  vpc_security_group_ids = [aws_security_group.allow_all_traffic.id]

  tags = merge(local.instance_tags, { Name = "${var.ec2_tags.Name}-instance" })
}
