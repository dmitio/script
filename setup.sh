#!/bin/bash

# Update package lists
apt-get update

# Install curl
apt-get update -y && apt-get install curl -y

# Install sudo if not installed
apt-get install -y sudo

# Install Docker
wget -qO- get.docker.com | bash

# Enable Docker service
systemctl enable docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Set executable permissions for Docker Compose
sudo chmod +x /usr/local/bin/docker-compose

echo "Over over"
