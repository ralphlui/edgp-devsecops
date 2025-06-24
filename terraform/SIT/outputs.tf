# outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public_subnet[*].id
}

output "private_subnet_a_ids" {
  description = "The IDs of the private subnets"
  value       = aws_subnet.private_subnet_a[*].id
}

output "private_subnet_b_ids" {
  description = "The IDs of the private subnets"
  value       = aws_subnet.private_subnet_b[*].id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.ig.id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_a_ids" {
  description = "The IDs of the private route tables"
  value       = aws_route_table.private_a[*].id
}

output "private_route_table_b_ids" {
  description = "The IDs of the private route tables"
  value       = aws_route_table.private_b[*].id
}

output "private_route_table_c_ids" {
  description = "The IDs of the private route tables"
  value       = aws_route_table.private_c.id
}

#output "redis_serverless_endpoint" {
#  value = aws_elasticache_serverless_cache.redis_serverless.endpoint[0].address
#}
