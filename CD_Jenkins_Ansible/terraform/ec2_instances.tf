# DevOps Server - All services in one instance
resource "aws_instance" "devops_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.xlarge" # 4 vCPU, 16 GB RAM - powerful enough for all services
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  
  # Use default VPC subnet
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 100 # 100GB for all services combined
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/devops_install.sh", {}))

  tags = {
    Name     = "DevOps-All-In-One-Server"
    Type     = "CI/CD-CodeQuality-ArtifactRepo-ConfigMgmt"
    Services = "Jenkins,SonarQube,Nexus,Ansible"
  }
}