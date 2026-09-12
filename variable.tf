

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "terraform-demo"
}

variable "ami" {
  type    = string
  default = "ami-03acbba64aef9bf5c"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.small"
}

variable "environment" {
  description   = "Product Environment"
  type          = string
  default       = "dev"
}