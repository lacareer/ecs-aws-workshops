output "custome_vpc_id" {
  value = aws_vpc.vpc.id
}

output "custom_vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

output "custome_vpc_private_subnet_ids" {
  value = [for subnet in aws_subnet.private_subnets[*] : subnet.id] # bcs rersources was created with count and is same with below
}

output "custome_vpc_public_subnet_ids" {
  value = [for subnet in aws_subnet.public_subnets[*] : subnet.id] # bcs rersources was created with count and is same with below
  #   value = aws_subnet.public_subnets[*].id
}

output "custome_vpc_private_route_table_ids" {
  value = [for route_table in aws_route_table.private_route_table : route_table.id] # bcs rersources was created with count and is same with below
  #   value = aws_route_table.private_route_table[*].id
}

output "custome_vpc_public_route_table_ids" {
  value = aws_route_table.public_route_table.id # was not created with count so no need to use splat operator
}