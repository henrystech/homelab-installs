#!/bin/bash

set -e

echo "🚀 Starting Arr Stack Installation..."

# Variables
INSTALL_DIR="/docker/arr-stack"
COMPOSE_URL="https://raw.githubusercontent.com/henrystech/arr-stack/main/docker-compose.yaml"

# Install Docker if not installed
if ! command -v docker &> /dev/null
then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
fi

# Install Docker Compose plugin if missing
if ! docker compose version &> /dev/null
then
    echo "📦 Installing Docker Compose..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
fi

# Create directory
sudo mkdir -p $INSTALL_DIR
sudo chown $USER:$USER $INSTALL_DIR

cd $INSTALL_DIR

# Download docker-compose file
echo "📥 Downloading docker-compose.yaml..."
curl -L $COMPOSE_URL -o docker-compose.yaml

# Create .env file if not exists
if [ ! -f ".env" ]; then
cat <<EOF > .env
PUID=1000
PGID=1000
TZ=America/Chicago
DOCKERCONFDIR=/volume1/docker/arr-stack
DOCKERSTORAGEDIR=/volume1/arr-stack-data
DOCKERLOGGING_MAXFILE=10
DOCKERLOGGING_MAXSIZE=200k
QBITTORRENT_PORT=8090
SABNZBD_PORT=8080
VPN_SERVICE_PROVIDER=private internet access
VPN_TYPE=openvpn
OPENVPN_USER=youruser
OPENVPN_PASSWORD=yourpass
SERVER_CITIES=Netherlands 
EOF
fi

# Create data folders
mkdir -p config data

echo "🐳 Starting containers..."
docker compose up -d

echo "✅ Installation Complete!"
echo "⚠️ You may need to log out and back in if Docker was just installed."