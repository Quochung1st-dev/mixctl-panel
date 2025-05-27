#!/bin/bash

# Check root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Install dependencies
echo "Installing dependencies..."
if [ -f /etc/debian_version ]; then
    # Check and remove existing packages
    echo "Checking for existing Nginx and Redis installations..."
    if dpkg -s nginx &> /dev/null; then
        echo "Removing existing Nginx..."
        apt purge -y nginx nginx-common libnginx-mod-http-lua # Add common and lua module for thorough removal
    fi
    if dpkg -s redis-server &> /dev/null; then
        echo "Removing existing Redis..."
        apt purge -y redis-server
    fi
    if dpkg -s luarocks &> /dev/null; then
        echo "Removing existing Luarocks..."
        apt purge -y luarocks
    fi

    # Add official Nginx repository
    echo "Adding official Nginx repository..."
    curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
    echo "deb http://nginx.org/packages/ubuntu/ $(lsb_release -cs) nginx" | tee /etc/apt/sources.list.d/nginx.list
    
    apt update
    apt upgrade -y # Add upgrade to ensure dependencies are met
    apt install -y nginx redis-server luarocks libnginx-mod-http-lua
    luarocks install lua-resty-http
    luarocks install lua-resty-redis
elif [ -f /etc/redhat-release ]; then
    # Check and remove existing packages
    echo "Checking for existing Nginx and Redis installations..."
    if rpm -q nginx &> /dev/null; then
        echo "Removing existing Nginx..."
        yum remove -y nginx
    fi
    if rpm -q redis &> /dev/null; then
        echo "Removing existing Redis..."
        yum remove -y redis
    fi
     if rpm -q luarocks &> /dev/null; then
        echo "Removing existing Luarocks..."
        yum remove -y luarocks
    fi
    
    yum install -y epel-release
    yum install -y nginx redis luarocks
    luarocks install lua-resty-http
    luarocks install lua-resty-redis
fi

# Create directories
echo "Creating directory structure..."
mkdir -p /etc/mix-cdn/{sites,ssl,cache}
mkdir -p /var/cache/mix/{nginx,redis}
mkdir -p /usr/local/lib/lua/ # Create Lua directory before copying
mkdir -p /etc/nginx/ # Ensure Nginx config directory exists
mkdir -p /etc/redis/ # Ensure Redis config directory exists

# Copy config files
echo "Copying configuration files..."
cp -r configs/nginx/* /etc/nginx/
cp configs/redis/redis.conf /etc/redis/
cp configs/lua/purge.lua /usr/local/lib/lua/

# Install main control script
echo "Installing mixctl..."
cp mixctl /usr/local/bin/
chmod +x /usr/local/bin/mixctl

# Install helper scripts
echo "Installing helper scripts..."
cp scripts/* /usr/local/bin/
chmod +x /usr/local/bin/{site-manager,ssl-manager,cache-manager}

# Create necessary directories
mkdir -p /etc/mix-cdn/ssl/.acme-challenge
chown -R www-data:www-data /etc/mix-cdn/ssl # Changed user/group to www-data

# Enable services
echo "Enabling services..."
systemctl enable nginx.service redis-server.service # Use full service unit names
systemctl restart nginx.service redis-server.service # Use full service unit names

echo "Installation completed!"
echo "Use 'mixctl' to manage your CDN."
