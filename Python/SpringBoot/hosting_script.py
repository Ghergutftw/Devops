#!/usr/bin/env python3
"""
Spring Boot Application Deployment Script for Ubuntu VM
Handles installation, deployment, and management of Spring Boot applications
"""

import os
import sys
import subprocess
import argparse
import logging
from pathlib import Path
import time
import json

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('springboot_deploy.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class SpringBootDeployer:
    def __init__(self, app_name, jar_file, port=8080, profile="prod"):
        self.app_name = app_name
        self.jar_file = jar_file
        self.port = port
        self.profile = profile
        self.app_dir = f"/opt/{app_name}"
        self.service_name = f"{app_name}.service"
        self.user = "springboot"

    def run_command(self, command, check=True, shell=True):
        """Execute shell command with error handling"""
        try:
            logger.info(f"Executing: {command}")
            result = subprocess.run(
                command,
                shell=shell,
                check=check,
                capture_output=True,
                text=True
            )
            if result.stdout:
                logger.info(f"Output: {result.stdout}")
            return result
        except subprocess.CalledProcessError as e:
            logger.error(f"Command failed: {e}")
            logger.error(f"Error output: {e.stderr}")
            raise

    def install_java(self):
        """Install Java 17 (recommended for Spring Boot 3.x)"""
        logger.info("Installing Java 17...")
        commands = [
            "sudo apt update",
            "sudo apt install -y openjdk-17-jdk",
            "sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-17-openjdk-amd64/bin/java 1",
            "sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-17-openjdk-amd64/bin/javac 1"
        ]

        for cmd in commands:
            self.run_command(cmd)

        # Verify Java installation
        java_version = self.run_command("java -version")
        logger.info("Java installed successfully")

    def create_user(self):
        """Create dedicated user for Spring Boot application"""
        logger.info(f"Creating user: {self.user}")
        try:
            self.run_command(f"sudo useradd -r -s /bin/false {self.user}")
        except subprocess.CalledProcessError:
            logger.info(f"User {self.user} already exists")

    def setup_directories(self):
        """Create necessary directories"""
        logger.info("Setting up directories...")
        directories = [
            self.app_dir,
            f"{self.app_dir}/logs",
            f"{self.app_dir}/config"
        ]

        for directory in directories:
            self.run_command(f"sudo mkdir -p {directory}")

        # Set ownership
        self.run_command(f"sudo chown -R {self.user}:{self.user} {self.app_dir}")

    def deploy_jar(self):
        """Deploy JAR file to application directory"""
        logger.info(f"Deploying JAR file: {self.jar_file}")

        if not os.path.exists(self.jar_file):
            raise FileNotFoundError(f"JAR file not found: {self.jar_file}")

        # Copy JAR file
        jar_name = f"{self.app_name}.jar"
        destination = f"{self.app_dir}/{jar_name}"

        self.run_command(f"sudo cp {self.jar_file} {destination}")
        self.run_command(f"sudo chown {self.user}:{self.user} {destination}")
        self.run_command(f"sudo chmod 755 {destination}")

        logger.info(f"JAR deployed to: {destination}")

    def create_systemd_service(self):
        """Create systemd service file"""
        logger.info("Creating systemd service...")

        service_content = f"""[Unit]
Description={self.app_name} Spring Boot Application
After=network.target

[Service]
Type=simple
User={self.user}
Group={self.user}
WorkingDirectory={self.app_dir}
ExecStart=/usr/bin/java -jar -Dspring.profiles.active={self.profile} -Dserver.port={self.port} {self.app_dir}/{self.app_name}.jar
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier={self.app_name}

# Environment variables
Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
Environment=SPRING_PROFILES_ACTIVE={self.profile}

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths={self.app_dir}/logs

[Install]
WantedBy=multi-user.target
"""

        service_path = f"/etc/systemd/system/{self.service_name}"

        # Write service file
        with open(f"/tmp/{self.service_name}", "w") as f:
            f.write(service_content)

        self.run_command(f"sudo mv /tmp/{self.service_name} {service_path}")
        self.run_command("sudo systemctl daemon-reload")

        logger.info("Systemd service created")

    def setup_nginx(self):
        """Setup Nginx as reverse proxy"""
        logger.info("Setting up Nginx...")

        # Install Nginx
        self.run_command("sudo apt install -y nginx")

        # Create Nginx configuration
        nginx_config = f"""server {{
    listen 80;
    server_name localhost;
    
    access_log /var/log/nginx/{self.app_name}.access.log;
    error_log /var/log/nginx/{self.app_name}.error.log;
    
    location / {{
        proxy_pass http://localhost:{self.port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }}
    
    # Health check endpoint
    location /actuator/health {{
        proxy_pass http://localhost:{self.port}/actuator/health;
        access_log off;
    }}
}}
"""

        config_path = f"/etc/nginx/sites-available/{self.app_name}"

        with open(f"/tmp/{self.app_name}_nginx", "w") as f:
            f.write(nginx_config)

        self.run_command(f"sudo mv /tmp/{self.app_name}_nginx {config_path}")
        self.run_command(f"sudo ln -sf {config_path} /etc/nginx/sites-enabled/")
        self.run_command("sudo nginx -t")
        self.run_command("sudo systemctl restart nginx")

        logger.info("Nginx configured successfully")

    def configure_firewall(self):
        """Configure UFW firewall"""
        logger.info("Configuring firewall...")

        commands = [
            "sudo ufw allow ssh",
            "sudo ufw allow 'Nginx Full'",
            f"sudo ufw allow {self.port}",
            "sudo ufw --force enable"
        ]

        for cmd in commands:
            self.run_command(cmd)

        logger.info("Firewall configured")

    def start_application(self):
        """Start the Spring Boot application"""
        logger.info("Starting Spring Boot application...")

        self.run_command(f"sudo systemctl enable {self.service_name}")
        self.run_command(f"sudo systemctl start {self.service_name}")

        # Wait for application to start
        time.sleep(10)

        # Check status
        status = self.run_command(f"sudo systemctl is-active {self.service_name}")
        if "active" in status.stdout:
            logger.info("Application started successfully")
        else:
            logger.error("Application failed to start")
            self.show_logs()

    def show_logs(self):
        """Show application logs"""
        logger.info("Showing application logs...")
        self.run_command(f"sudo journalctl -u {self.service_name} --no-pager -n 50")

    def show_status(self):
        """Show application status"""
        logger.info("Application status:")
        self.run_command(f"sudo systemctl status {self.service_name}")

    def stop_application(self):
        """Stop the application"""
        logger.info("Stopping application...")
        self.run_command(f"sudo systemctl stop {self.service_name}")

    def restart_application(self):
        """Restart the application"""
        logger.info("Restarting application...")
        self.run_command(f"sudo systemctl restart {self.service_name}")

    def health_check(self):
        """Perform health check"""
        logger.info("Performing health check...")
        try:
            result = self.run_command(f"curl -f http://localhost:{self.port}/actuator/health")
            logger.info("Health check passed")
            return True
        except subprocess.CalledProcessError:
            logger.error("Health check failed")
            return False

    def deploy(self):
        """Full deployment process"""
        logger.info(f"Starting deployment of {self.app_name}")

        try:
            self.install_java()
            self.create_user()
            self.setup_directories()
            self.deploy_jar()
            self.create_systemd_service()
            self.setup_nginx()
            self.configure_firewall()
            self.start_application()

            # Final health check
            if self.health_check():
                logger.info("Deployment completed successfully!")
                logger.info(f"Application is available at: http://localhost")
                logger.info(f"Direct access: http://localhost:{self.port}")
            else:
                logger.error("Deployment completed but health check failed")

        except Exception as e:
            logger.error(f"Deployment failed: {e}")
            sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Deploy Spring Boot application to Ubuntu VM")
    parser.add_argument("--app-name", required=True, help="Application name")
    parser.add_argument("--jar-file", required=True, help="Path to JAR file")
    parser.add_argument("--port", type=int, default=8080, help="Application port (default: 8080)")
    parser.add_argument("--profile", default="prod", help="Spring profile (default: prod)")

    # Actions
    parser.add_argument("--deploy", action="store_true", help="Deploy application")
    parser.add_argument("--start", action="store_true", help="Start application")
    parser.add_argument("--stop", action="store_true", help="Stop application")
    parser.add_argument("--restart", action="store_true", help="Restart application")
    parser.add_argument("--status", action="store_true", help="Show application status")
    parser.add_argument("--logs", action="store_true", help="Show application logs")
    parser.add_argument("--health", action="store_true", help="Perform health check")

    args = parser.parse_args()

    deployer = SpringBootDeployer(
        app_name=args.app_name,
        jar_file=args.jar_file,
        port=args.port,
        profile=args.profile
    )

    if args.deploy:
        deployer.deploy()
    elif args.start:
        deployer.start_application()
    elif args.stop:
        deployer.stop_application()
    elif args.restart:
        deployer.restart_application()
    elif args.status:
        deployer.show_status()
    elif args.logs:
        deployer.show_logs()
    elif args.health:
        deployer.health_check()
    else:
        parser.print_help()

if __name__ == "__main__":
    main()