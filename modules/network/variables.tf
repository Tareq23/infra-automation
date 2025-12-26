

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "all_trafic"{
    description = "Route ALL traffic to internet"
    type = string
    default = "0.0.0.0/0"
}

variable "vpc_cird" {
  description = "CIDR block for VPC"
  type        = string
  default     = "23.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "23.0.1.0/24"
}

variable "private_subbet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "23.0.2.0/24"
}

variable "availability_zone" {
  description = "AWS availability zone"
  type        = string
}

