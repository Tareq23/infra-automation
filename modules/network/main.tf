

resource "aws_vpc" "sysdops_vpc"{
    cidr_block = var.vpc_cird
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "${var.environment}-VPC"
        Environment = var.environment
    }
}

resource "aws_subnet" "sysdops_public"{
    vpc_id = aws_vpc.sysdops_vpc.id
    cidr_block = var.public_subnet_cidr
    availability_zone = var.availability_zone
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.environment}-public-subnet"
        Environment = var.environment
    }
}

resource "aws_subnet" "sysdops_private"{
    vpc_id = aws_vpc.sysdops_vpc.id
    cidr_block = var.private_subbet_cidr
    availability_zone = var.availability_zone

    tags = {
        Name = "${var.environment}-private-subnet"
        Environment = var.environment
    }
}

resource "aws_internet_gateway" "sysdops_igw" {
  vpc_id = aws_vpc.sysdops_vpc.id

  tags = {
    Name = "Sysdops Internet Gateway"
  }
}

resource "aws_route_table" "sysdops_route" {
  vpc_id = aws_vpc.sysdops_vpc.id

  route {
    cidr_block = var.all_trafic
    gateway_id = aws_internet_gateway.sysdops_igw.id
  }

  tags = {
    Name = "Sysdops Route Table"
  }
}

resource "aws_route_table_association" "sysdops_route_table_association" {
  subnet_id      = aws_subnet.sysdops_public.id
  route_table_id = aws_route_table.sysdops_route.id
}

resource "aws_security_group" "sysdops_sg" {
  name   = "sg"
  vpc_id = aws_vpc.sysdops_vpc.id

  ingress{
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress{
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress{
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}





