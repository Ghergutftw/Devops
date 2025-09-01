#!/bin/bash

# Update package list and install necessary packages
sudo apt update
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql php-curl php-gd php-xml php-mbstring wget unzip

# Create a directory for the web server
sudo mkdir -p /var/www/html
sudo chown -R www-data:www-data /var/www/html

# Download and extract WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
sudo rsync -av wordpress/ /var/www/html/
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;

# Enable Apache mod_rewrite
sudo a2enmod rewrite

# Restart Apache to apply changes
sudo systemctl restart apache2

# Set up MySQL database for WordPress
DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASS="wppassword"
sudo mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Configure WordPress wp-config.php
cd /var/www/html
if [ ! -f wp-config.php ]; then
    sudo cp wp-config-sample.php wp-config.php
    sudo sed -i "s/database_name_here/${DB_NAME}/" wp-config.php
    sudo sed -i "s/username_here/${DB_USER}/" wp-config.php
    sudo sed -i "s/password_here/${DB_PASS}/" wp-config.php
    sudo chown www-data:www-data wp-config.php
fi