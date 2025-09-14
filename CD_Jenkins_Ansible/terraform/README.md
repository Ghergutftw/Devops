# DevOps Infrastructure with Terraform

This Terraform configuration creates a complete DevOps infrastructure on AWS with Jenkins, SonarQube, and Nexus servers.

## Architecture

The infrastructure includes:

- **VPC** with public subnet for internet access
- **Jenkins Server** (t3.medium) - CI/CD automation server
- **SonarQube Server** (t3.medium) - Code quality analysis
- **Nexus Server** (t3.medium) - Artifact repository manager
- **Security Groups** configured for secure access from your IP only
- **Inter-service communication** enabled within the VPC

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with your credentials
3. **Terraform** installed (>= 1.0)
4. **EC2 Key Pair** created in your target AWS region (optional, for SSH access)

## Quick Start

1. **Clone and navigate to the terraform directory**
   ```bash
   cd terraform
   ```

2. **Configure variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Apply the configuration**
   ```bash
   terraform apply
   ```

## Configuration

### Required Variables

- `key_pair_name`: Name of your AWS EC2 Key Pair (for SSH access)
  - Create one in AWS EC2 Console if you don't have it
  - Or comment out the `key_name` lines in `ec2_instances.tf` if SSH isn't needed

### Optional Variables

- `aws_region`: AWS region (default: us-west-2)
- `project_name`: Project name for resource tagging
- `environment`: Environment name

## Instance Specifications

| Service   | Instance Type | vCPU | RAM | Storage | Port |
|-----------|---------------|------|-----|---------|------|
| Jenkins   | t3.medium     | 2    | 4GB | 20GB    | 8080 |
| SonarQube | t3.medium     | 2    | 4GB | 30GB    | 9000 |
| Nexus     | t3.medium     | 2    | 4GB | 50GB    | 8081 |

## Security

- **Network Access**: Only your public IP can access the web interfaces
- **Internal Communication**: All services can communicate within the VPC
- **Encryption**: EBS volumes are encrypted
- **SSH Access**: Restricted to your IP (if key pair is configured)

## After Deployment

Terraform will output the public IPs and URLs for all services:

### Jenkins
- URL: `http://<jenkins-ip>:8080`
- Initial admin password: SSH to the instance and run:
  ```bash
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
  ```

### SonarQube
- URL: `http://<sonarqube-ip>:9000`
- Default credentials: `admin/admin`
- You'll be prompted to change the password on first login

### Nexus
- URL: `http://<nexus-ip>:8081`
- Admin password: SSH to the instance and run:
  ```bash
  sudo cat /opt/sonatype-work/nexus3/admin.password
  ```

## Service Installation Details

### Jenkins
- Pre-installed with Java 11
- Includes Docker, Docker Compose, AWS CLI, Terraform, Maven, Node.js
- Ready for CI/CD pipeline development

### SonarQube
- Configured with PostgreSQL database
- System optimizations applied
- Ready for code quality analysis

### Nexus
- Configured with Java 8
- Optimized JVM settings
- Ready for artifact management

## Clean Up

To destroy all resources:
```bash
terraform destroy
```

## Estimated Costs

Running all three t3.medium instances 24/7 will cost approximately:
- **Compute**: ~$95-105/month (depending on region)
- **Storage**: ~$10-15/month
- **Data Transfer**: Varies based on usage

Consider stopping instances when not in use to reduce costs.

## Troubleshooting

### Services not accessible
1. Check security groups allow your current IP
2. Verify instances are running and healthy
3. Services may take 5-10 minutes to fully start after instance launch

### SSH Access Issues
1. Ensure key pair name in terraform.tfvars matches AWS
2. Verify your IP is allowed in security groups
3. Use the correct username: `ubuntu`

### Service Installation Issues
1. Check instance logs: `sudo journalctl -u <service-name>`
2. Verify user data scripts executed: `sudo cat /var/log/cloud-init-output.log`

## Additional Notes

- All services are configured with reasonable defaults for development/testing
- For production use, consider using Application Load Balancers and certificates
- Database credentials for SonarQube are set to defaults - change for production
- Consider implementing backup strategies for persistent data