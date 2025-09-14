# Outputs for EKS EC2 Terraform configuration

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.eks_ec2.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.eks_ec2.public_ip
}

output "ec2_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.eks_ec2.private_ip
}

output "elastic_ip" {
  description = "Elastic IP address (if created)"
  value       = var.create_elastic_ip ? aws_eip.eks_ec2_eip[0].public_ip : null
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.eks_ec2_sg.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role attached to the EC2 instance"
  value       = aws_iam_role.eks_ec2_role.arn
}

output "key_pair_name" {
  description = "Name of the key pair used"
  value       = var.create_key_pair ? aws_key_pair.eks_ec2_key[0].key_name : var.existing_key_name
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.create_key_pair ? aws_key_pair.eks_ec2_key[0].key_name : var.existing_key_name}.pem ubuntu@${var.create_elastic_ip ? aws_eip.eks_ec2_eip[0].public_ip : aws_instance.eks_ec2.public_ip}"
}
