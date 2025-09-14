#!/bin/bash
# Verification script to check all installed tools

echo "=== EKS Client EC2 Instance - Tool Verification ==="
echo "Date: $(date)"
echo ""

# Function to check command and display result
check_tool() {
    local tool_name="$1"
    local command="$2"
    
    echo -n "Checking $tool_name... "
    if command -v ${command%% *} >/dev/null 2>&1; then
        echo "✅ INSTALLED"
        $command 2>/dev/null || echo "   (Warning: Command failed but binary exists)"
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
echo "ubuntu user groups: $(groups ubuntu 2>/dev/null || echo 'User not found')"
echo "gitlab-runner user groups: $(groups gitlab-runner 2>/dev/null || echo 'User not found')"

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
