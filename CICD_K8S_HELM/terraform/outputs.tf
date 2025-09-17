output "devops_server_public_ip" {
  description = "Public IP address of the DevOps server"
  value       = aws_instance.devops_server.public_ip
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "http://${aws_instance.devops_server.public_ip}:8080"
}

output "sonarqube_url" {
  description = "URL to access SonarQube"
  value       = "http://${aws_instance.devops_server.public_ip}:9000"
}

output "nexus_url" {
  description = "URL to access Nexus"
  value       = "http://${aws_instance.devops_server.public_ip}:8081"
}

output "jenkins_admin_password" {
  description = "Command to get Jenkins initial admin password"
  value       = "docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
}

output "nexus_admin_password" {
  description = "Command to get Nexus initial admin password"
  value       = "docker exec nexus cat /nexus-data/admin.password"
}

output "sonarqube_credentials" {
  description = "SonarQube default login credentials"
  value       = "admin/admin (change on first login)"
}

output "ssh_connection" {
  description = "SSH command to connect to the DevOps server"
  value       = "ssh -i ${var.key_pair_name}.pem ubuntu@${aws_instance.devops_server.public_ip}"
}

output "service_status_check" {
  description = "Command to check all services status (run after SSH)"
  value       = "./check-services.sh"
}

output "ansible_setup" {
  description = "Command to set up Ansible workspace (run after SSH)"
  value       = "./setup-ansible.sh"
}

output "ansible_usage" {
  description = "How to use Ansible (native installation)"
  value = {
    check_version    = "ansible --version"
    run_playbook     = "ansible-playbook ~/ansible/playbooks/sample-playbook.yml"
    run_adhoc        = "ansible all -i ~/ansible/inventory/hosts -m ping"
    test_local       = "ansible localhost -m ping"
    workspace        = "/home/ubuntu/ansible/"
    config_file      = "/etc/ansible/ansible.cfg"
  }
}

output "all_service_urls" {
  description = "All service URLs for easy access"
  value = {
    jenkins   = "http://${aws_instance.devops_server.public_ip}:8080"
    sonarqube = "http://${aws_instance.devops_server.public_ip}:9000"
    nexus     = "http://${aws_instance.devops_server.public_ip}:8081"
  }
}

output "your_ip" {
  description = "Your current public IP address (whitelisted in security group)"
  value       = chomp(data.http.myip.response_body)
}