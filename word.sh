#!/bin/bash

# Variables
DB_ROOT_PASSWORD="ahdfjti456"
DB_NAME="wordpress_db"
DB_USER="wordpress_user"
DB_PASSWORD="wordpress_password"
WP_URL="https://wordpress.org/latest.tar.gz"
WP_DIR="/var/www/html/wordpress"

# Update and install necessary packages
sudo yum update -y
sudo yum install -y httpd mariadb-server mariadb php php-mysqlnd php-fpm php-cli tar wget

# Start and enable Apache
sudo systemctl start httpd
sudo systemctl enable httpd

# Start and enable MariaDB
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Secure MariaDB installation
sudo mysql_secure_installation <<EOF

y
$DB_ROOT_PASSWORD
$DB_ROOT_PASSWORD
y
y
y
y
EOF

# Create WordPress database and user
mysql -u root -p"$DB_ROOT_PASSWORD" <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

# Download and extract WordPress
wget $WP_URL -O /tmp/latest.tar.gz
sudo tar -zxvf /tmp/latest.tar.gz -C /var/www/html/
sudo mv /var/www/html/wordpress $WP_DIR

# Set permissions
sudo chown -R apache:apache $WP_DIR
sudo chmod -R 755 $WP_DIR

# Configure Apache
sudo tee /etc/httpd/conf.d/wordpress.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot "$WP_DIR"
    ServerName sunenergyguide.com
    ServerAlias www.sunenergyguide.com
    <Directory "$WP_DIR">
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog /var/log/httpd/wordpress-error.log
    CustomLog /var/log/httpd/wordpress-access.log combined
</VirtualHost>
EOF

# Restart Apache
sudo systemctl restart httpd

# Set up WordPress configuration
sudo cp $WP_DIR/wp-config-sample.php $WP_DIR/wp-config.php
sudo sed -i "s/database_name_here/$DB_NAME/" $WP_DIR/wp-config.php
sudo sed -i "s/username_here/$DB_USER/" $WP_DIR/wp-config.php
sudo sed -i "s/password_here/$DB_PASSWORD/" $WP_DIR/wp-config.php

# Set up SELinux
sudo chcon -t httpd_sys_rw_content_t $WP_DIR -R

echo "WordPress installation is complete. Please navigate to your server's IP address to complete the setup through the web interface."
