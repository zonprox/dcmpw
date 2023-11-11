#!/bin/bash

# DCMP (Debian Caddy MariaDB PHP) Installation Script

# Colors for formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display information with color
display_info() {
  printf "${GREEN}==============================================${NC}\n"
  printf "${GREEN}$1${NC}\n"
  printf "${GREEN}==============================================${NC}\n"
}

# Set locale
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Set timezone
sudo timedatectl set-timezone Asia/Ho_Chi_Minh

# Set nameserver
echo -e "${YELLOW}Setting nameserver...${NC}"
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee /etc/resolv.conf

# Enable TCP BBR congestion control
echo -e "${YELLOW}Enabling TCP BBR congestion control...${NC}"
cat <<EOF | sudo tee /etc/sysctl.conf
# TCP BBR congestion control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

# Create swap
echo -e "${YELLOW}Creating swap...${NC}"
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-xs-swappiness.conf

# Install Caddy
echo -e "${YELLOW}Installing Caddy...${NC}"
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt stable main' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install -y caddy

# Prompt user for domain and email
echo -e "${YELLOW}Configuring Caddy...${NC}"
read -p "Your domain (e.g., example.com): " DOMAIN
DOMAIN=${DOMAIN:-example.com}

read -p "Your email for SSL certificate: " EMAIL

# Display configuration information
display_info "Installation Completed!"
echo -e "Domain: ${GREEN}$DOMAIN${NC}"
echo -e "Email: ${GREEN}$EMAIL${NC}"

# Configure Caddyfile
echo -e "${YELLOW}Configuring Caddyfile...${NC}"
echo "${DOMAIN} {
    root * /var/www/${DOMAIN}/wordpress
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
echo -e "${YELLOW}Installing PHP extensions...${NC}"
sudo apt install -y php-curl php-gd php-gmp php-intl php-mbstring php-soap php-xml php-xmlrpc php-imagick php-zip php-mysql php-fpm
sudo sed -i 's/;upload_max_filesize = 2M/upload_max_filesize = 64M/' /etc/php/7.4/fpm/php.ini
sudo sed -i 's/;post_max_size = 8M/post_max_size = 64M/' /etc/php/7.4/fpm/php.ini
sudo sed -i 's/;max_execution_time = 30/max_execution_time = 180/' /etc/php/7.4/fpm/php.ini
sudo sed -i 's/;max_input_vars = 1000/max_input_vars = 10000/' /etc/php/7.4/fpm/php.ini

# Restart PHP
echo -e "${YELLOW}Restarting PHP...${NC}"
sudo systemctl restart php7.4-fpm.service

# Remove Apache2
echo -e "${YELLOW}Removing Apache2...${NC}"
sudo apt purge -y apache2*

# Restart PHP
echo -e "${YELLOW}Restarting PHP...${NC}"
sudo systemctl restart php7.4-fpm.service

# Install MariaDB
echo -e "${YELLOW}Installing MariaDB...${NC}"
sudo apt install -y mariadb-server
sudo mysql_secure_installation

# Prompt user for database information
echo -e "${YELLOW}Configuring Database...${NC}"
read -p "Database name ('${DOMAIN}_db'): " DB_NAME
DB_NAME=${DB_NAME:-${DOMAIN}_db}

read -p "Database username ('${DOMAIN}_user'): " DB_USER
DB_USER=${DB_USER:-${DOMAIN}_user}

read -p "Database password ('password'): " DB_PASSWORD
DB_PASSWORD=${DB_PASSWORD:-password}

# Display database information
display_info "Database Information:"
echo -e "Domain: ${GREEN}$DOMAIN${NC}"
echo -e "Database Name: ${GREEN}$DB_NAME${NC}"
echo -e "Database User: ${GREEN}$DB_USER${NC}"
echo -e "Database Password: ${GREEN}$DB_PASSWORD${NC}"

# Get WordPress
echo -e "${YELLOW}Installing WordPress...${NC}"
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

# Remove the downloaded WordPress archive
rm -f /var/www/$DOMAIN/latest.tar.gz

# Start Caddy
echo -e "${YELLOW}Starting Caddy...${NC}"
sudo systemctl start caddy
