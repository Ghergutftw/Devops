#!/bin/bash
set -e

# Log everything to a file for debugging
exec > >(tee /var/log/devops-install.log) 2>&1

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y openjdk-17-jdk unzip wget curl htop python3 python3-pip software-properties-common

# Install Ansible
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible

# Install additional Python packages for Ansible
pip3 install requests boto3 docker-py

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Create Docker network for services to communicate
docker network create devops-network

# Create data directories
mkdir -p /jenkins-data /sonar-data /nexus-data

# Set proper permissions
chown -R 1000:1000 /jenkins-data
chown -R 1000:1000 /sonar-data
chown -R 200:200 /nexus-data

# Set proper permissions for SonarQube subdirectories
mkdir -p /sonar-data/data /sonar-data/logs /sonar-data/extensions
chown -R 1000:1000 /sonar-data/data /sonar-data/logs /sonar-data/extensions
chmod -R 777 /sonar-data

# System optimizations for SonarQube
echo 'vm.max_map_count=524288' >> /etc/sysctl.conf
echo 'fs.file-max=131072' >> /etc/sysctl.conf
echo 'vm.swappiness=1' >> /etc/sysctl.conf
sysctl -p

# Set ulimits for SonarQube
echo 'sonarqube   -   nofile   131072' >> /etc/security/limits.conf
echo 'sonarqube   -   nproc    8192' >> /etc/security/limits.conf
echo '*   -   nofile   131072' >> /etc/security/limits.conf
echo '*   -   nproc    8192' >> /etc/security/limits.conf

# Run Jenkins container
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  --network devops-network \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /jenkins-data:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e JAVA_OPTS="-Djava.awt.headless=true -Xmx2g -Xms1g" \
  jenkins/jenkins:lts-jdk17

# Run SonarQube container
docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  --network devops-network \
  -p 9000:9000 \
  -v /sonar-data/data:/opt/sonarqube/data \
  -v /sonar-data/logs:/opt/sonarqube/logs \
  -v /sonar-data/extensions:/opt/sonarqube/extensions \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  --user 1000:1000 \
  sonarqube:community

# Run Nexus container
docker run -d \
  --name nexus \
  --restart unless-stopped \
  --network devops-network \
  -p 8081:8081 \
  -v /nexus-data:/nexus-data \
  -e INSTALL4J_ADD_VM_PARAMS="-Xms1g -Xmx2g -XX:MaxDirectMemorySize=2g" \
  sonatype/nexus3:latest

# Create Ansible directories
mkdir -p /etc/ansible
mkdir -p /home/ubuntu/ansible/{playbooks,inventory,roles,vars,collections,group_vars,host_vars}

# Set proper permissions for Ansible directories
chown -R ubuntu:ubuntu /home/ubuntu/ansible
chmod -R 755 /home/ubuntu/ansible

# Create Ansible configuration file
cat > /etc/ansible/ansible.cfg << 'EOF'
[defaults]
inventory = /home/ubuntu/ansible/inventory/hosts
host_key_checking = False
timeout = 30
gathering = smart
fact_caching = memory
remote_user = ubuntu
private_key_file = /home/ubuntu/.ssh/id_rsa

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
pipelining = True
EOF

# Copy SSH key for ubuntu user (if it exists)
if [ -f /home/ubuntu/.ssh/authorized_keys ]; then
    # Generate SSH key pair for ubuntu user if not exists
    sudo -u ubuntu ssh-keygen -t rsa -b 4096 -f /home/ubuntu/.ssh/id_rsa -N "" 2>/dev/null || true
    chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa*
    chmod 600 /home/ubuntu/.ssh/id_rsa
    chmod 644 /home/ubuntu/.ssh/id_rsa.pub
fi

# Wait for services to start
sleep 120

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Create a status script for easy checking
cat > /home/ubuntu/check-services.sh << 'EOF'
#!/bin/bash
echo "DevOps Services Status:"
echo "======================"
echo "Docker containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "Service URLs:"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Jenkins: http://$PUBLIC_IP:8080"
echo "SonarQube: http://$PUBLIC_IP:9000" 
echo "Nexus: http://$PUBLIC_IP:8081"
echo ""
echo "Ansible Status:"
ansible --version | head -1
echo "Ansible config: /etc/ansible/ansible.cfg"
echo "Ansible workspace: /home/ubuntu/ansible/"
echo ""
echo "Get passwords:"
echo "Jenkins: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
echo "Nexus: docker exec nexus cat /nexus-data/admin.password"
echo "SonarQube: admin/admin"
echo ""
echo "Ansible usage:"
echo "Run playbooks: ansible-playbook ~/ansible/playbooks/your-playbook.yml"
echo "Run ad-hoc commands: ansible all -i ~/ansible/inventory/hosts -m ping"
echo "Check connectivity: ansible all -m ping"
EOF

# Create sample Ansible files
cat > /home/ubuntu/setup-ansible.sh << 'EOF'
#!/bin/bash
echo "Setting up Ansible workspace..."

# Create sample inventory
tee /home/ubuntu/ansible/inventory/hosts << 'HOSTS'
[webservers]
# Add your target servers here
# example: web1.example.com ansible_host=10.0.1.10 ansible_user=ubuntu

[databases]
# Add your database servers here
# example: db1.example.com ansible_host=10.0.1.20 ansible_user=ubuntu

[local]
localhost ansible_connection=local

[all:vars]
ansible_ssh_private_key_file=/home/ubuntu/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
HOSTS

# Create sample playbook
tee /home/ubuntu/ansible/playbooks/sample-playbook.yml << 'PLAYBOOK'
---
- name: Sample Ansible Playbook
  hosts: all
  become: yes
  tasks:
    - name: Update package cache
      apt:
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: Install basic packages
      apt:
        name:
          - htop
          - curl
          - wget
          - vim
        state: present
      when: ansible_os_family == "Debian"
    
    - name: Check system information
      debug:
        msg: "System {{ inventory_hostname }} has OS {{ ansible_distribution }} {{ ansible_distribution_version }}"
    
    - name: Create a test file
      file:
        path: /tmp/ansible-test
        state: touch
        mode: '0644'
PLAYBOOK

# Create local test playbook
tee /home/ubuntu/ansible/playbooks/local-test.yml << 'LOCALTEST'
---
- name: Local Test Playbook
  hosts: localhost
  connection: local
  become: yes
  tasks:
    - name: Check if Docker is running
      service:
        name: docker
        state: started
    
    - name: List running containers
      command: docker ps --format "table {{.Names}}\t{{.Status}}"
      register: containers
    
    - name: Display containers
      debug:
        var: containers.stdout_lines
LOCALTEST

# Create group_vars example
mkdir -p /home/ubuntu/ansible/group_vars
tee /home/ubuntu/ansible/group_vars/all.yml << 'GROUPVARS'
---
# Global variables for all hosts
timezone: "UTC"
ntp_servers:
  - "pool.ntp.org"
  - "time.google.com"

# Common packages to install on all systems
common_packages:
  - curl
  - wget
  - htop
  - vim
GROUPVARS

echo "Ansible workspace setup complete!"
echo "Files created in /home/ubuntu/ansible/"
echo ""
echo "Test Ansible with:"
echo "  ansible localhost -m ping"
echo "  ansible-playbook ~/ansible/playbooks/local-test.yml"
echo ""
echo "Add your servers to ~/ansible/inventory/hosts and test with:"
echo "  ansible all -m ping"
EOF

chmod +x /home/ubuntu/check-services.sh
chown ubuntu:ubuntu /home/ubuntu/check-services.sh

chmod +x /home/ubuntu/setup-ansible.sh
chown ubuntu:ubuntu /home/ubuntu/setup-ansible.sh

# Run the Ansible setup
/home/ubuntu/setup-ansible.sh