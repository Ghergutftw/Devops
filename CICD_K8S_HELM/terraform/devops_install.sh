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