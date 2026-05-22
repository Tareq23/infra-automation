

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.sysdops_vpc.id
}

output "public_subnet_1_id" {
  description = "ID of the public subnet 1"
  value       = aws_subnet.sysdops_public_1.id
}

output "public_subnet_2_id" {
  description = "ID of the public subnet 2"
  value       = aws_subnet.sysdops_public_2.id
}

output "private_subnet_1_id" {
  description = "ID of the private subnet 1"
  value       = aws_subnet.sysdops_private_1.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.sysdops_vpc.cidr_block
}




output "security_group_id"{
    description = "Security Group ID"
    value = aws_security_group.sysdops_sg.id
}

