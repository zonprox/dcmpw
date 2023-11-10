#!/bin/bash

# LCMP (Linux Caddy Mariadb PHP) Installation Script

# Update OS
sudo apt update && sudo apt full-upgrade -y

# Set locale
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Set timezone
sudo timedatectl set-timezone Asia/Ho_Chi_Minh

# Set nameserver
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee /etc/resolv.conf

# Enable TCP BBR congestion control
cat <<EOF | sudo tee /etc/sysctl.conf
# TCP BBR congestion control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

# Create swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-xs-swappiness.conf

# Install Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt stable main' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install -y caddy

# Prompt user for domain and email
read -p "Enter your domain (e.g., example.com): " DOMAIN
read -p "Enter your email for SSL certificate: " EMAIL

# Configure Caddyfile
echo "$DOMAIN {
    root * /var/www/$DOMAIN/htdocs
    encode zstd gzip

    @disallowed {
        path /xmlrpc.php
        path /wp-content/uploads/*.php
    }

    rewrite @disallowed /index.php

    # Serve a PHP site through php-fpm
    php_fastcgi unix//run/php/php7.4-fpm.sock

    @static {
        file
        path *.css *.js *.ico *.woff *.woff2
    }
    handle @static {
        header Cache-Control \"public, max-age=31536000\"
    }

    @static-img {
        file
        path *.gif *.jpg *.jpeg *.png *.svg *.webp *.avif
    }
    handle @static-img {
        header Cache-Control \"public, max-age=31536000, immutable\"
    }

    # Enable the static file server.
    file_server {
        precompressed zstd gzip
        index index.html
    }

    log {
        output file /var/log/caddy/ssl_access.log {
            roll_size 100mb
            roll_keep 3
            roll_keep_for 7d
        }
    }
}" | sudo tee /etc/caddy/Caddyfile

# Install PHP extensions
sudo apt install -y php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip php-mysql php-fpm

# Remove Apache2
sudo apt purge -y apache2*

# Restart PHP
sudo systemctl restart php7.4-fpm.service

# Install MariaDB
sudo apt install -y mariadb-server
sudo mysql_secure_installation

# Prompt user for database information
read -p "Enter the database name (press Enter to use default '$DOMAIN_db'): " DB_NAME
DB_NAME=${DB_NAME:-${DOMAIN}_db}

read -p "Enter the database username (press Enter to use default '$DOMAIN_user'): " DB_USER
DB_USER=${DB_USER:-${DOMAIN}_user}

read -p "Enter the database password (press Enter to use default 'password'): " DB_PASSWORD
DB_PASSWORD=${DB_PASSWORD:-password}

# Create database
sudo mysql -uroot <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $DB_NAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Get WordPress
sudo mkdir -p /var/www/$DOMAIN
cd /var/www/$DOMAIN
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
sudo chown -R www-data:www-data /var/www/$DOMAIN/wordpress
sudo find /var/www/$DOMAIN/wordpress/ -type d -exec chmod 755 {} \;
sudo find /var/www/$DOMAIN/wordpress/ -type f -exec chmod 644 {} \;

# Auto-configure WordPress database
cd /var/www/$DOMAIN/wordpress
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/$DB_NAME/" wp-config.php
sed -i "s/username_here/$DB_USER/" wp-config.php
sed -i "s/password_here/$DB_PASSWORD/" wp-config.php
sed -i "s/localhost/127.0.0.1/" wp-config.php

# Start Caddy
sudo systemctl start caddy
