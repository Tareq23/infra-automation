

resource "aws_vpc" "sysdops_vpc"{
    cidr_block = var.vpc_cird
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "${var.environment}-VPC"
        Environment = var.environment
    }
}

resource "aws_subnet" "sysdops_public_1"{
    vpc_id = aws_vpc.sysdops_vpc.id
    cidr_block = var.public_subnet_1_cidr
    availability_zone = var.availability_zone[0]
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.environment}-public-subnet"
        Environment = var.environment
    }
}

resource "aws_subnet" "sysdops_public_2"{
    vpc_id = aws_vpc.sysdops_vpc.id
    cidr_block = var.public_subnet_2_cidr
    availability_zone = var.availability_zone[1]
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.environment}-public-subnet"
        Environment = var.environment
    }
}

resource "aws_subnet" "sysdops_private_1"{
    vpc_id = aws_vpc.sysdops_vpc.id
    cidr_block = var.private_subbet_1_cidr
    availability_zone = var.availability_zone[0]

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

resource "aws_route_table_association" "sysdops_route_table_association_for_public_subnet_1" {
  subnet_id      = aws_subnet.sysdops_public_1.id
  route_table_id = aws_route_table.sysdops_route.id
}

resource "aws_route_table_association" "sysdops_route_table_association_for_public_subnet_2" {
  subnet_id      = aws_subnet.sysdops_public_2.id
  route_table_id = aws_route_table.sysdops_route.id
}

resource "aws_security_group" "sysdops_sg" {
  name   = "sg"
  vpc_id = aws_vpc.sysdops_vpc.id

  ingress{
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.all_trafic]
  }
  ingress{
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [var.all_trafic]
  }
  ingress{
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [var.all_trafic]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.all_trafic]
  }
}


resource "aws_network_acl" "sysdops_public_nacl" {
  vpc_id = aws_vpc.sysdops_vpc.id

  subnet_ids = [
    aws_subnet.sysdops_public_1.id,
    aws_subnet.sysdops_public_2.id
  ]

  #############################################
  # INBOUND RULES (traffic coming INTO subnet)
  #############################################
  
  # Allow SSH inbound
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # Allow HTTP inbound
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Allow HTTPS inbound
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow PostgreSQL inbound
  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 5432
    to_port    = 5432
  }

  # Allow port 8080 inbound
  ingress {
    protocol   = "tcp"
    rule_no    = 500
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 8080
    to_port    = 8080
  }

  # CRITICAL: Allow response traffic from internet (ephemeral ports)
  # This allows responses from apt repositories, Docker Hub, etc.
  ingress {
    protocol   = "tcp"
    rule_no    = 600
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow DNS responses inbound (UDP)
  ingress {
    protocol   = "udp"
    rule_no    = 700
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 53
    to_port    = 53
  }

  #############################################
  # OUTBOUND RULES (traffic going OUT of subnet)
  #############################################

  # Allow HTTP outbound (for apt updates)
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Allow HTTPS outbound (for Docker, secure updates)
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow DNS queries outbound (UDP)
  egress {
    protocol   = "udp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 53
    to_port    = 53
  }

  # Allow outbound ephemeral ports (for outgoing connections)
  egress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  
  tags = {
    Name = "sysdops_public_nacl"
  }
}




