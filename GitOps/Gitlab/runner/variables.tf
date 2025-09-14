# Variables for EKS EC2 Terraform configuration

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "eks-client"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH to the EC2 instance"
  type        = list(string)
  default     = ["128.127.116.233/32"] # Your current IP address
}

variable "create_key_pair" {
  description = "Whether to create a new key pair or use existing one"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "Public key content for the key pair (required if create_key_pair is true)"
  type        = string
  default     = ""
}

variable "existing_key_name" {
  description = "Name of existing key pair to use (required if create_key_pair is false)"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "create_elastic_ip" {
  description = "Whether to create and attach an Elastic IP"
  type        = bool
  default     = false
}
