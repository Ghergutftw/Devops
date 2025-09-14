# EKS Client EC2 Instance - Terraform Configuration

This Terraform configuration creates an EC2 instance with the necessary permissions and tools to interact with Amazon EKS clusters.

## Features

- **EC2 Instance**: Ubuntu 22.04 LTS with pre-installed EKS tools
- **IAM Role**: Proper permissions for EKS cluster access
- **Security Group**: Configured for SSH and HTTPS access
- **Tools Installed**: AWS CLI, kubectl, Helm 3, eksctl, Docker
- **Auto-configuration**: Ready to connect to EKS clusters

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version >= 1.0)
3. **EC2 Key Pair** (existing or create new one)
4. **Appropriate AWS permissions** to create EC2, IAM, and VPC resources

## Quick Start

### 1. Clone and Navigate

```bash
cd eks-terraform
```

### 2. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
aws_region = "us-east-1"
project_name = "my-eks-client"
instance_type = "t3.medium"
allowed_ssh_cidr = ["YOUR_IP/32"]  # Replace with your IP
existing_key_name = "your-key-pair-name"
```

### 3. Deploy

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 4. Connect to Instance

After deployment, use the SSH command from the output:

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@<public-ip>
```

## Configuration Options

### EC2 Instance

- **Instance Type**: Configurable (default: t3.medium)
- **AMI**: Latest Ubuntu 22.04 LTS
- **Storage**: Encrypted EBS volume (default: 20GB)
- **Networking**: Uses default VPC and subnet

### Security

- **Security Group**: SSH (22), HTTP (8080), HTTPS (443)
- **IAM Role**: EKS read permissions, EC2 read permissions
- **SSH Access**: Configurable CIDR blocks

### Key Pair Options

**Option 1: Use Existing Key Pair**
```hcl
create_key_pair = false
existing_key_name = "my-existing-key"
```

**Option 2: Create New Key Pair**
```hcl
create_key_pair = true
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQAB..."
```

## Installed Tools

The EC2 instance comes pre-configured with:

- **AWS CLI v2**: For AWS service interaction
- **kubectl**: Kubernetes command-line tool
- **Helm 3**: Kubernetes package manager
- **eksctl**: EKS cluster management tool
- **Docker**: Container runtime
- **Git, curl, jq**: Utility tools

## Connecting to EKS Clusters

### Using the Helper Script

```bash
./connect-to-eks.sh <cluster-name> [region]
```

### Manual Connection

```bash
aws eks update-kubeconfig --region us-east-1 --name my-cluster
kubectl get nodes
```

## File Structure

```
eks-terraform/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── user-data.sh           # EC2 startup script
├── terraform.tfvars.example # Example variables file
└── README.md               # This file
```

## Outputs

After successful deployment, you'll get:

- **ec2_instance_id**: EC2 instance identifier
- **ec2_public_ip**: Public IP address
- **ec2_private_ip**: Private IP address
- **security_group_id**: Security group identifier
- **iam_role_arn**: IAM role ARN
- **ssh_command**: Ready-to-use SSH command

## Security Considerations

1. **Restrict SSH Access**: Limit `allowed_ssh_cidr` to your IP
2. **Key Management**: Secure your private key file
3. **IAM Permissions**: The instance has read-only EKS permissions
4. **Security Groups**: Review and adjust as needed

## Cost Optimization

- **Instance Type**: Use t3.small for development/testing
- **Elastic IP**: Only enable if you need a static IP
- **Monitoring**: Set up CloudWatch billing alerts

## Troubleshooting

### Common Issues

1. **Key Pair Not Found**
   - Ensure the key pair exists in the specified region
   - Verify the key name in terraform.tfvars

2. **Permission Denied (SSH)**
   - Check security group rules
   - Verify your IP is in allowed_ssh_cidr
   - Ensure correct private key file permissions (600)

3. **EKS Connection Issues**
   - Verify EKS cluster exists and is active
   - Check IAM permissions
   - Ensure cluster is in the same region

### Logs

Check EC2 user data execution:
```bash
sudo cat /var/log/user-data.log
sudo cat /var/log/cloud-init-output.log
```

## Verification Tools

The EC2 instance includes several verification tools:

### **Available Scripts:**
- **`./verify-tools.sh`** - Comprehensive tool verification script
- **`./register-gitlab-runner.sh`** - GitLab Runner registration helper
- **`GITLAB_RUNNER_README.md`** - GitLab Runner setup documentation

### **Log Files:**
- **`installation-status.log`** - Installation verification results
- **`/var/log/cloud-init-output.log`** - System installation logs

### **Quick Verification:**
```bash
# SSH to your instance
ssh -i ~/.ssh/my-eks-client-ec2-key.pem ubuntu@<public-ip>

# Run the verification script
./verify-tools.sh

# Check installation log
cat installation-status.log
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Support

For issues related to:
- **Terraform**: Check Terraform documentation
- **AWS EKS**: Check AWS EKS documentation
- **kubectl**: Check Kubernetes documentation

## License

This configuration is provided as-is for educational and development purposes.
