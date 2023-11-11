#!/bin/bash

# DCMP (Debian Caddy MariaDB PHP) Installation Script

# Set colors for better visualization
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Set locale
echo -e "${YELLOW}Setting locale...${NC}"
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Set timezone
echo -e "${YELLOW}Setting timezone...${NC}"
sudo timedatectl set-timezone Asia/Ho_Chi_Minh

# Set nameserver
echo -e "${YELLOW}Setting Google and Cloudflare nameservers...${NC}"
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee /etc/resolv.conf

# Enable TCP BBR congestion control
echo -e "${YELLOW}Enabling TCP BBR congestion control...${NC}"
cat <<EOF | sudo tee /etc/sysctl.conf
# TCP BBR congestion control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

# Create swap
echo -e "${YELLOW}Creating a 2GB swap file...${NC}"
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
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy -y

# Prompt user for domain and email
read -p "$(echo -e ${YELLOW}"[?] Your domain (e.g., example.com): "${NC})" DOMAIN
read -p "$(echo -e ${YELLOW}"[?] Your email for SSL certificate: "${NC})" EMAIL

#!/bin/bash

# DCMP (Debian Caddy MariaDB PHP) Installation Script

# Set colors for better visualization
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Set locale
echo -e "${YELLOW}Setting locale...${NC}"
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Set timezone
echo -e "${YELLOW}Setting timezone...${NC}"
sudo timedatectl set-timezone Asia/Ho_Chi_Minh

# Set nameserver
echo -e "${YELLOW}Setting Google and Cloudflare nameservers...${NC}"
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee /etc/resolv.conf

# Enable TCP BBR congestion control
echo -e "${YELLOW}Enabling TCP BBR congestion control...${NC}"
cat <<EOF | sudo tee /etc/sysctl.conf
# TCP BBR congestion control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

# Create swap
echo -e "${YELLOW}Creating a 2GB swap file...${NC}"
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
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy -y

# Prompt user for domain and email
read -p "$(echo -e ${YELLOW}"[?] Your domain (e.g., example.com): "${NC})" DOMAIN
read -p "$(echo -e ${YELLOW}"[?] Your email for SSL certificate: "${NC})" EMAIL

# Download Caddyfile from GitHub
CADDYFILE_URL="https://raw.githubusercontent.com/zonprox/dcmpw/main/Caddyfile"
echo -e "${YELLOW}Downloading Caddyfile...${NC}"
sudo curl -sSL "$CADDYFILE_URL" -o /etc/caddy/Caddyfile

# Update Caddyfile with user's domain
echo -e "${YELLOW}Updating Caddyfile with your domain...${NC}"
sudo sed -i "s/example.com/$DOMAIN/g" /etc/caddy/Caddyfile

# Install PHP extensions
echo -e "${YELLOW}Installing PHP extensions${NC}"
sudo apt install -y php-curl php-gd php-gmp php-intl php-mbstring php-soap php-xml php-xmlrpc php-imagick php-zip php-mysql php-fpm
sudo sed -i 's/;upload_max_filesize = 2M/upload_max_filesize = 64M/' /etc/php/7.4/fpm/php.ini
sudo sed -i 's/;post_max_size = 8M/post_max_size = 64M/' /etc/php/7.4/fpm/php.ini
sudo sed -i 's/;max_execution_time = 30/max_execution_time = 180/' /etc/php/7.4/fpm/php.ini
sudo sed -i 's/;max_input_vars = 1000/max_input_vars = 10000/' /etc/php/7.4/fpm/php.ini

# Restart PHP
sudo systemctl restart php7.4-fpm.service

# Remove Apache2
echo -e "${YELLOW}Removing Apache2...${NC}"
sudo apt purge -y apache2*

# Restart PHP
sudo systemctl restart php7.4-fpm.service

# Install MariaDB
echo -e "${YELLOW}Installing MariaDB...${NC}"
sudo apt install -y mariadb-server

# Automatically set root password for MariaDB
MYSQL_ROOT_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16 ; echo '')
sudo mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_ROOT_PASSWORD');"

# Prompt user for database information
read -p "$(echo -e ${YELLOW}"[?] Database name ('$DOMAIN_db'): "${NC})" DB_NAME
DB_NAME=${DB_NAME:-${DOMAIN}_db}

read -p "$(echo -e ${YELLOW}"[?] Database username ('$DOMAIN_user'): "${NC})" DB_USER
DB_USER=${DB_USER:-${DOMAIN}_user}

# Prompt user for database password, generate random if not provided
read -p "$(echo -e ${YELLOW}"[?] Database password ('password', press Enter for random): "${NC})" DB_PASSWORD
DB_PASSWORD=${DB_PASSWORD:-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16 ; echo '')}

# Create database
sudo mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $DB_NAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Get WordPress
echo -e "${YELLOW}Downloading and configuring WordPress...${NC}"
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

# Display configuration information
echo -e "${GREEN}Installation and configuration completed.${NC}"
echo -e "${YELLOW}Configuration Information:${NC}"
echo -e "Domain: ${GREEN}$DOMAIN${NC}"
echo -e "Email: ${GREEN}$EMAIL${NC}"
echo -e "${YELLOW}MariaDB Information:${NC}"
echo -e "Root Database Password: ${GREEN}$MYSQL_ROOT_PASSWORD${NC}"
echo -e "Database Name: ${GREEN}$DB_NAME${NC}"
echo -e "Database User: ${GREEN}$DB_USER${NC}"
echo -e "Database Password: ${GREEN}$DB_PASSWORD${NC}"

# Clean up
echo -e "${YELLOW}Cleaning up...${NC}"