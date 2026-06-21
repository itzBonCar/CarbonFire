output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = { for key, subnet in aws_subnet.public : key => subnet.id }
}

output "app_subnet_ids" {
  value = { for key, subnet in aws_subnet.app : key => subnet.id }
}

output "middleware_subnet_ids" {
  value = { for key, subnet in aws_subnet.middleware : key => subnet.id }
}
