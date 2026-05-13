#!/bin/bash
set -euo pipefail

echo "=== ArcStack EC2 Setup ==="

# Update system
sudo yum update -y 2>/dev/null || sudo apt-get update -y

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo yum install -y docker 2>/dev/null || (curl -fsSL https://get.docker.com | sudo sh)
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $(whoami)
    echo "Docker installed. You may need to re-login for group changes."
fi

# Install Docker Compose v2
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose..."
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    sudo curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" \
        -o /usr/local/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    echo "Docker Compose installed."
fi

# Install Git
if ! command -v git &> /dev/null; then
    sudo yum install -y git 2>/dev/null || sudo apt-get install -y git
fi

# Create swap (essential for t2.micro 1GB)
if [ ! -f /swapfile ]; then
    echo "Creating 2GB swap file..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
    echo "Swap created."
fi

echo "=== Setup complete ==="
echo "Next: clone repos, copy .env, run deploy.sh"
