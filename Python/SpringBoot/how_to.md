# Spring Boot VM Deployment Guide

This guide explains how to use the Python deployment script to host your Spring Boot application on an Ubuntu VM.

## Prerequisites

Before running the deployment script, ensure you have:

### System Requirements
- Ubuntu 18.04 or later
- Root or sudo access
- At least 2GB RAM (4GB+ recommended)
- At least 10GB free disk space
- Internet connection for package downloads

### Required Files
- Your Spring Boot JAR file (built with `mvn clean package` or `gradle build`)
- The Python deployment script (`deploy_springboot.py`)

### Python Dependencies
The script uses only standard Python libraries, but ensure you have Python 3.6+ installed:

```bash
python3 --version
# If not installed:
sudo apt update
sudo apt install python3 python3-pip
```

## Quick Start

### 1. Download and Prepare the Script

```bash
# Make the script executable
chmod +x deploy_springboot.py

# Verify your JAR file exists
ls -la your-app.jar
```

### 2. Deploy Your Application

For a complete deployment with all components:

```bash
sudo python3 deploy_springboot.py \
    --app-name myapp \
    --jar-file ./myapp-1.0.0.jar \
    --port 8080 \
    --profile prod \
    --deploy
```

### 3. Verify Deployment

Check if your application is running:

```bash
# Check application status
sudo python3 deploy_springboot.py --app-name myapp --jar-file ./myapp-1.0.0.jar --status

# Perform health check
sudo python3 deploy_springboot.py --app-name myapp --jar-file ./myapp-1.0.0.jar --health

# View logs
sudo python3 deploy_springboot.py --app-name myapp --jar-file ./myapp-1.0.0.jar --logs
```

## Command Reference

### Deployment Command

```bash
sudo python3 deploy_springboot.py \
    --app-name <APPLICATION_NAME> \
    --jar-file <PATH_TO_JAR> \
    [--port <PORT_NUMBER>] \
    [--profile <SPRING_PROFILE>] \
    --deploy
```

**Parameters:**
- `--app-name`: Name of your application (used for service and directory names)
- `--jar-file`: Path to your Spring Boot JAR file
- `--port`: Application port (default: 8080)
- `--profile`: Spring Boot profile (default: prod)
- `--deploy`: Execute full deployment

### Management Commands

#### Start Application
```bash
sudo python3 deploy_springboot.py --app-name myapp --jar-file ./myapp.jar --start
```

#### Stop Application
```bash
sudo python3 deploy_springboot.py --app-name myapp --jar-file ./myapp.jar --stop
```

#### Restart Application
```bash
sudo python3 deploy_springboot.py --app-name myapp --jar-file ./myapp.jar --restart
```

#### Check Status
```bash
sudo python3 deploy_springboot.py --app-name myapp --jar-file ./myapp.jar --status
```

#### View Logs
```bash
sudo python3 deploy_springboot.py --app-name myapp --jar-file ./myapp.jar --logs
```

#### Health Check
```bash
sudo python3 deploy_springboot.py --app-name myapp --jar-file ./myapp.jar --health
```

## What the Script Does

### 1. Java Installation
- Installs OpenJDK 17 (recommended for Spring Boot 3.x)
- Sets up Java alternatives
- Configures JAVA_HOME environment variable

### 2. User and Directory Setup
- Creates dedicated `springboot` user for security
- Creates application directory structure:
  ```
  /opt/myapp/
  ├── myapp.jar
  ├── logs/
  └── config/
  ```

### 3. Application Deployment
- Copies JAR file to `/opt/myapp/`
- Sets proper file permissions
- Creates systemd service file

### 4. Nginx Configuration
- Installs and configures Nginx as reverse proxy
- Sets up server block for your application
- Configures logging and health check endpoints

### 5. Firewall Setup
- Configures UFW firewall
- Opens necessary ports (SSH, HTTP, your app port)

### 6. Service Management
- Creates systemd service for automatic startup
- Enables service to start on boot
- Starts the application

## File Locations

After deployment, your application files will be located at:

```
/opt/myapp/                          # Application directory
├── myapp.jar                        # Your JAR file
├── logs/                            # Application logs
└── config/                          # Configuration files

/etc/systemd/system/myapp.service    # Systemd service file
/etc/nginx/sites-available/myapp     # Nginx configuration
/var/log/nginx/myapp.access.log      # Nginx access logs
/var/log/nginx/myapp.error.log       # Nginx error logs
```

## Accessing Your Application

After successful deployment:

- **Via Nginx (recommended)**: `http://your-server-ip/`
- **Direct access**: `http://your-server-ip:8080/`
- **Health check**: `http://your-server-ip/actuator/health`

## Common Use Cases

### Development Environment
```bash
sudo python3 deploy_springboot.py \
    --app-name myapp-dev \
    --jar-file ./myapp-dev.jar \
    --port 8081 \
    --profile dev \
    --deploy
```

### Production Environment
```bash
sudo python3 deploy_springboot.py \
    --app-name myapp-prod \
    --jar-file ./myapp-prod.jar \
    --port 8080 \
    --profile prod \
    --deploy
```

### Multiple Applications
You can deploy multiple applications by using different app names and ports:

```bash
# App 1
sudo python3 deploy_springboot.py \
    --app-name app1 \
    --jar-file ./app1.jar \
    --port 8080 \
    --deploy

# App 2
sudo python3 deploy_springboot.py \
    --app-name app2 \
    --jar-file ./app2.jar \
    --port 8081 \
    --deploy
```

## Troubleshooting

### Check Application Status
```bash
sudo systemctl status myapp.service
```

### View Detailed Logs
```bash
sudo journalctl -u myapp.service -f  # Follow logs in real-time
sudo journalctl -u myapp.service -n 100  # Last 100 lines
```

### Check Nginx Status
```bash
sudo systemctl status nginx
sudo nginx -t  # Test configuration
```

### Check Port Usage
```bash
sudo netstat -tlnp | grep 8080
```

### Check Firewall Status
```bash
sudo ufw status
```

### Common Issues and Solutions

#### Issue: Application fails to start
```bash
# Check Java installation
java -version

# Check JAR file permissions
ls -la /opt/myapp/myapp.jar

# Check service file syntax
sudo systemctl daemon-reload
```

#### Issue: Cannot access application
```bash
# Check if application is running
curl http://localhost:8080/actuator/health

# Check Nginx configuration
sudo nginx -t
sudo systemctl restart nginx
```

#### Issue: Port already in use
```bash
# Find process using the port
sudo lsof -i :8080

# Kill process if needed
sudo kill -9 <PID>
```

## Updating Your Application

To update your application with a new JAR file:

1. Stop the current application:
   ```bash
   sudo python3 deploy_springboot.py --app-name myapp --jar-file ./myapp.jar --stop
   ```

2. Deploy the new version:
   ```bash
   sudo python3 deploy_springboot.py --app-name myapp --jar-file ./myapp-new.jar --deploy
   ```

## Security Considerations

- The application runs under a dedicated `springboot` user
- Firewall is configured to only allow necessary ports
- Nginx provides an additional security layer
- Application logs are properly configured
- Systemd service includes security hardening options

## Monitoring

### System Resources
```bash
# Check CPU and memory usage
top
htop

# Check disk usage
df -h
```

### Application Metrics
If your Spring Boot app includes Actuator:
- Health: `http://your-server/actuator/health`
- Metrics: `http://your-server/actuator/metrics`
- Info: `http://your-server/actuator/info`

## Next Steps

After successful deployment, consider:

1. Setting up SSL certificates (Let's Encrypt)
2. Configuring log rotation
3. Setting up monitoring and alerting
4. Implementing backup strategies
5. Configuring database connections
6. Setting up environment-specific configurations

## Support

If you encounter issues:

1. Check the deployment logs: `tail -f springboot_deploy.log`
2. Review systemd service logs: `sudo journalctl -u myapp.service`
3. Verify all prerequisites are met
4. Ensure all file paths are correct
5. Check system resources and permissions