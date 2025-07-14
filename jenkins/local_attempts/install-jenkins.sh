#!/bin/bash

# Exit on error
set -e

# Update packages
sudo apt-get update

# Install Java (Jenkins dependency)
sudo apt-get install -y openjdk-21-jdk

# Add Jenkins repo and key
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Update and install Jenkins
sudo apt-get update
sudo apt-get install -y jenkins

# Enable and start Jenkins service
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Print the initial admin password
echo "Jenkins installed successfully!"
echo "Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
