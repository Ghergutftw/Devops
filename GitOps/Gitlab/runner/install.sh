#!/bin/bash

# Exit on any error
set -e

# Update the system
echo "Updating system packages..."
apt-get update -y

# Install required packages
echo "Installing required packages..."
apt-get install -y curl unzip git jq apt-transport-https ca-certificates gnupg lsb-release

# Install AWS CLI v2
echo "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws/

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Helm 3 (using official installation script - more reliable)
echo "Installing Helm 3..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install eksctl
echo "Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

# Install Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker
usermod -a -G docker ubuntu

# Install GitLab Runner
echo "Installing GitLab Runner..."
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash
apt-get install -y gitlab-runner

# Add gitlab-runner user to docker group
usermod -a -G docker gitlab-runner

# Configure AWS CLI region
sudo -u ubuntu aws configure set region ${aws_region}
sudo -u ubuntu aws configure set output json

# Create GitLab Runner registration script
cat > /home/ubuntu/register-gitlab-runner.sh << 'SCRIPT_EOF'
#!/bin/bash
# Script to register GitLab Runner with your GitLab repository
# Usage: ./register-gitlab-runner.sh <gitlab-url> <registration-token> [runner-name] [tags]

GITLAB_URL=$${1:-"https://gitlab.com/"}
REGISTRATION_TOKEN=$$2
RUNNER_NAME=$${3:-"eks-ec2-runner"}
TAGS=$${4:-"docker,eks,aws,kubernetes"}

if [ -z "$$REGISTRATION_TOKEN" ]; then
    echo "Usage: $$0 <gitlab-url> <registration-token> [runner-name] [tags]"
    echo ""
    echo "Example:"
    echo "  $$0 https://gitlab.com/ glrt-xxxxxxxxxxxxxxxxxxxx my-runner docker,eks,aws"
    echo ""
    echo "To get your registration token:"
    echo "1. Go to your GitLab project"
    echo "2. Settings > CI/CD > Runners"
    echo "3. Copy the registration token"
    exit 1
fi

echo "Registering GitLab Runner..."
echo "GitLab URL: $$GITLAB_URL"
echo "Runner Name: $$RUNNER_NAME"
echo "Tags: $$TAGS"

sudo gitlab-runner register \
  --non-interactive \
  --url "$$GITLAB_URL" \
  --registration-token "$$REGISTRATION_TOKEN" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "$$RUNNER_NAME" \
  --tag-list "$$TAGS" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected"

echo "GitLab Runner registered successfully!"
echo "You can check the status with: sudo gitlab-runner status"
SCRIPT_EOF

chmod +x /home/ubuntu/register-gitlab-runner.sh
chown ubuntu:ubuntu /home/ubuntu/register-gitlab-runner.sh

# Create a README for GitLab Runner setup
cat > /home/ubuntu/GITLAB_RUNNER_README.md << 'README_EOF'
# GitLab Runner Setup

This EC2 instance has GitLab Runner installed and ready to be registered with your GitLab repository.

## Quick Registration

Use the provided script to register the runner:

```bash
./register-gitlab-runner.sh <gitlab-url> <registration-token> [runner-name] [tags]
```

### Example:
```bash
./register-gitlab-runner.sh https://gitlab.com/ glrt-xxxxxxxxxxxxxxxxxxxx my-eks-runner docker,eks,aws,kubernetes
```

## Getting Your Registration Token

1. Go to your GitLab project
2. Navigate to **Settings > CI/CD**
3. Expand the **Runners** section
4. Copy the registration token from "Project runners"

## Manual Registration

If you prefer to register manually:

```bash
sudo gitlab-runner register
```

Follow the prompts and provide:
- GitLab instance URL (e.g., https://gitlab.com/)
- Registration token
- Runner description
- Tags (e.g., docker,eks,aws,kubernetes)
- Executor: docker
- Default Docker image: alpine:latest

## Useful Commands

- Check runner status: `sudo gitlab-runner status`
- List registered runners: `sudo gitlab-runner list`
- Start runner: `sudo gitlab-runner start`
- Stop runner: `sudo gitlab-runner stop`
- Unregister runner: `sudo gitlab-runner unregister --url <gitlab-url> --token <runner-token>`

## Runner Configuration

The runner is configured to:
- Use Docker executor
- Run both tagged and untagged jobs
- Access Docker daemon (gitlab-runner user is in docker group)
- Have access to AWS CLI, kubectl, helm, eksctl

## Security Note

This runner has Administrator AWS privileges through the EC2 instance IAM role.
Be careful with the jobs you run and consider restricting permissions if needed.
README_EOF

chown ubuntu:ubuntu /home/ubuntu/GITLAB_RUNNER_README.md

# Create verification script
cat > /home/ubuntu/verify-tools.sh << 'VERIFY_EOF'
#!/bin/bash
# Verification script to check all installed tools

echo "=== EKS Client EC2 Instance - Tool Verification ==="
echo "Date: $$(date)"
echo ""

# Function to check command and display result
check_tool() {
    local tool_name="$$1"
    local command="$$2"
    
    echo -n "Checking $$tool_name... "
    if command -v $${command%% *} >/dev/null 2>&1; then
        echo "✅ INSTALLED"
        $$command 2>/dev/null || echo "   (Warning: Command failed but binary exists)"
    else
        echo "❌ NOT FOUND"
        return 1
    fi
}

# Check all tools
check_tool "AWS CLI" "aws --version"
echo ""
check_tool "kubectl" "kubectl version --client"
echo ""
check_tool "Helm" "helm version"
echo ""
check_tool "eksctl" "eksctl version"
echo ""
check_tool "Docker" "docker --version"
echo ""
check_tool "GitLab Runner" "gitlab-runner --version"
echo ""

# Check Docker service
echo -n "Checking Docker service... "
if systemctl is-active --quiet docker; then
    echo "✅ RUNNING"
else
    echo "❌ NOT RUNNING"
fi

echo -n "Checking GitLab Runner service... "
if systemctl is-active --quiet gitlab-runner; then
    echo "✅ RUNNING"
else
    echo "❌ NOT RUNNING"
fi

echo ""

# Check AWS configuration
echo "=== AWS Configuration ==="
aws configure list 2>/dev/null || echo "AWS CLI not configured"

echo ""

# Check user groups
echo "=== User Groups ==="
echo "ubuntu user groups: $$(groups ubuntu 2>/dev/null || echo 'User not found')"
echo "gitlab-runner user groups: $$(groups gitlab-runner 2>/dev/null || echo 'User not found')"

echo ""

# Check helper files
echo "=== Helper Files ==="
if [ -f "/home/ubuntu/register-gitlab-runner.sh" ]; then
    echo "✅ GitLab Runner registration script available"
else
    echo "❌ GitLab Runner registration script missing"
fi

if [ -f "/home/ubuntu/GITLAB_RUNNER_README.md" ]; then
    echo "✅ GitLab Runner documentation available"
else
    echo "❌ GitLab Runner documentation missing"
fi

echo ""
echo "=== Verification Complete ==="
VERIFY_EOF

chmod +x /home/ubuntu/verify-tools.sh
chown ubuntu:ubuntu /home/ubuntu/verify-tools.sh

# Verify installations
echo "Verifying tool installations..."
echo "=== Installation Verification ===" > /home/ubuntu/installation-status.log
echo "Date: $(date)" >> /home/ubuntu/installation-status.log

# Test AWS CLI
if aws --version >> /home/ubuntu/installation-status.log 2>&1; then
    echo "✅ AWS CLI: INSTALLED" >> /home/ubuntu/installation-status.log
else
    echo "❌ AWS CLI: FAILED" >> /home/ubuntu/installation-status.log
fi

# Test kubectl
if kubectl version --client >> /home/ubuntu/installation-status.log 2>&1; then
    echo "✅ kubectl: INSTALLED" >> /home/ubuntu/installation-status.log
else
    echo "❌ kubectl: FAILED" >> /home/ubuntu/installation-status.log
fi

# Test Helm
if helm version >> /home/ubuntu/installation-status.log 2>&1; then
    echo "✅ Helm: INSTALLED" >> /home/ubuntu/installation-status.log
else
    echo "❌ Helm: FAILED" >> /home/ubuntu/installation-status.log
fi

# Test eksctl
if eksctl version >> /home/ubuntu/installation-status.log 2>&1; then
    echo "✅ eksctl: INSTALLED" >> /home/ubuntu/installation-status.log
else
    echo "❌ eksctl: FAILED" >> /home/ubuntu/installation-status.log
fi

# Test Docker
if docker --version >> /home/ubuntu/installation-status.log 2>&1; then
    echo "✅ Docker: INSTALLED" >> /home/ubuntu/installation-status.log
else
    echo "❌ Docker: FAILED" >> /home/ubuntu/installation-status.log
fi

# Test GitLab Runner
if gitlab-runner --version >> /home/ubuntu/installation-status.log 2>&1; then
    echo "✅ GitLab Runner: INSTALLED" >> /home/ubuntu/installation-status.log
else
    echo "❌ GitLab Runner: FAILED" >> /home/ubuntu/installation-status.log
fi

echo "Installation completed! Check /home/ubuntu/installation-status.log for verification results."
chown ubuntu:ubuntu /home/ubuntu/installation-status.log

gitlab-deploy

gldt-PQADD1Bh69ST-zdYK4-t