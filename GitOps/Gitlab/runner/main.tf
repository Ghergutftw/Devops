# Terraform configuration for EC2 instance with EKS access
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Data source to get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to get subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Data source to get the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for EC2 instance
resource "aws_security_group" "eks_ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance with EKS access"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # HTTP access (if needed for kubectl proxy or web interfaces)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# IAM Role for EC2 instance
resource "aws_iam_role" "eks_ec2_role" {
  name = "${var.project_name}-ec2-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-eks-role"
  }
}

# IAM Policy for EKS access
resource "aws_iam_policy" "eks_access_policy" {
  name        = "${var.project_name}-eks-access-policy"
  description = "Policy for EC2 to access EKS clusters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeUpdate",
          "eks:ListUpdates",
          "eks:DescribeFargateProfile",
          "eks:ListFargateProfiles",
          "eks:DescribeAddon",
          "eks:ListAddons",
          "eks:DescribeAddonVersions",
          "eks:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach EKS access policy to the role
resource "aws_iam_role_policy_attachment" "eks_access_policy_attachment" {
  role       = aws_iam_role.eks_ec2_role.name
  policy_arn = aws_iam_policy.eks_access_policy.arn
}

# Attach AWS managed policy for EC2 instance profile
resource "aws_iam_role_policy_attachment" "ec2_instance_profile" {
  role       = aws_iam_role.eks_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# Attach Administrator Access policy for full AWS permissions
resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.eks_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "eks_ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.eks_ec2_role.name
}

# Key pair for EC2 instance
resource "aws_key_pair" "eks_ec2_key" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.project_name}-ec2-key"
  public_key = var.public_key

  tags = {
    Name = "${var.project_name}-ec2-key"
  }
}

# EC2 Instance
resource "aws_instance" "eks_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.create_key_pair ? aws_key_pair.eks_ec2_key[0].key_name : var.existing_key_name
  vpc_security_group_ids = [aws_security_group.eks_ec2_sg.id]
  subnet_id              = data.aws_subnets.default.ids[0]
  iam_instance_profile   = aws_iam_instance_profile.eks_ec2_profile.name

  # User data script to install kubectl and AWS CLI
  user_data = base64encode(templatefile("${path.module}/install.sh", {
    aws_region = var.aws_region
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-ec2-eks"
    Type = "EKS-Client"
  }
}

# Elastic IP for the EC2 instance (optional)
resource "aws_eip" "eks_ec2_eip" {
  count    = var.create_elastic_ip ? 1 : 0
  instance = aws_instance.eks_ec2.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-ec2-eip"
  }
}
