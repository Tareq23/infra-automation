

provider "aws"{
  region      = var.aws_region
  access_key  = var.aws_access_key
  secret_key  = var.aws_secret_key
}

resource "aws_key_pair" "main_key" {

  key_name      = "mti_key_pair"
  public_key    = file("/home/tareq/.ssh/id_rsa.pub")

}

resource "aws_security_group" "frontend_app_sg" {
  name        = "Web-SG"
  description = "Application security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application-security-group"
  }
}


resource "aws_instance" "frontend_instance"{
  ami                 = var.ami
  instance_type       = var.instance_type
  key_name            = aws_key_pair.main_key.key_name
  vpc_security_group_ids = [
    aws_security_group.frontend_app_sg.id
  ]
}
