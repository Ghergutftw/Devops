variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair for EC2 instances"
  type        = string
  # You need to create this key pair in AWS EC2 console before running terraform
  # Or comment out the key_name lines in ec2_instances.tf if you don't want SSH access
}

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
  default     = "DevOps-Pipeline"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}