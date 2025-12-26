

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

module "network" {
  source = "./modules/network"
  
  environment                 = "dev"
  availability_zone   = "${var.aws_region}a"
  
}

resource "aws_key_pair" "main_key" {

  key_name   = "mti_key_pair"
  public_key = file("/home/tareq/.ssh/id_rsa.pub")

}




resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.main_key.key_name
  subnet_id     = module.network.public_subnet_id
  vpc_security_group_ids = [module.network.security_group_id]
}
