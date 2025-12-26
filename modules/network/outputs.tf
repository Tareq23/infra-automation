

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.sysdops_vpc.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.sysdops_public.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.sysdops_vpc.cidr_block
}


output "security_group_id"{
    description = "Security Group ID"
    value = aws_security_group.sysdops_sg.id
}