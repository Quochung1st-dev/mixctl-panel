#!/bin/bash

# Check root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Install dependencies
echo "Installing dependencies..."
if [ -f /etc/debian_version ]; then
    apt update
    apt upgrade -y # Add upgrade to ensure dependencies are met
    apt install -y nginx redis-server luarocks libnginx-mod-http-lua
    luarocks install lua-resty-http
    luarocks install lua-resty-redis
elif [ -f /etc/redhat-release ]; then
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
chown -R nginx:nginx /etc/mix-cdn/ssl

# Enable services
echo "Enabling services..."
systemctl enable nginx redis
systemctl restart nginx redis

echo "Installation completed!"
echo "Use 'mixctl' to manage your CDN."
