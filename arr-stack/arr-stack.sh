#!/bin/bash

set -e

#########################################
# 🚀 FULL SERVER SETUP: NFS + ARR STACK
#########################################

echo "🚀 Starting Full Setup (Synology NFS + Arr Stack)..."

#########################################
# 🔧 EDIT THESE VARIABLES
#########################################

NAS_IP="192.168.1.10"               # Synology IP address
NAS_EXPORT="/volume1/data"          # NFS path from Nas 
MOUNT_POINT="/mnt/data"             # Where Ubuntu will mount it
NFS_VERSION="4"                     # Recommended: 4

INSTALL_DIR="/docker"
COMPOSE_URL="https://git.henrystech.dev/l0rdmusash1/bash-installs/raw/branch/main/filehunter/docker-compose.yaml"

#########################################

# Must run as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Please run as root (sudo ./full-setup.sh)"
   exit 1
fi

#########################################
# 📦 INSTALL NFS CLIENT
#########################################

echo "📦 Installing NFS client packages..."
apt update
apt install -y nfs-common curl

#########################################
# 📁 SETUP NFS MOUNT
#########################################

echo "📁 Creating mount point..."
mkdir -p "$MOUNT_POINT"

echo "🔎 Testing connection to NAS..."
showmount -e "$NAS_IP" || {
    echo "❌ Unable to reach NAS or NFS not enabled."
    exit 1
}

echo "🔗 Mounting NFS share..."
mount -t nfs -o vers=$NFS_VERSION "$NAS_IP:$NAS_EXPORT" "$MOUNT_POINT"

echo "💾 Adding to /etc/fstab..."
FSTAB_ENTRY="$NAS_IP:$NAS_EXPORT $MOUNT_POINT nfs defaults,_netdev,vers=$NFS_VERSION 0 0"

if ! grep -qs "$NAS_IP:$NAS_EXPORT" /etc/fstab; then
    echo "$FSTAB_ENTRY" >> /etc/fstab
fi

echo "✅ Verifying mount..."
mount -a

#########################################
# 🐳 INSTALL DOCKER
#########################################

if ! command -v docker &> /dev/null
then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker $SUDO_USER
fi

#########################################
# 🐳 INSTALL DOCKER COMPOSE
#########################################

if ! docker compose version &> /dev/null
then
    echo "📦 Installing Docker Compose..."
    apt-get update
    apt-get install -y docker-compose-plugin
fi

#########################################
# 📂 SETUP ARR STACK
#########################################

echo "📁 Creating install directory..."
mkdir -p $INSTALL_DIR
chown $SUDO_USER:$SUDO_USER $INSTALL_DIR

cd $INSTALL_DIR

echo "📥 Downloading docker-compose.yaml..."
curl -L $COMPOSE_URL -o docker-compose.yaml

#########################################
# ⚙️ CREATE ENV FILE
#########################################

if [ ! -f ".env" ]; then
cat <<EOF > .env
PUID=1000
PGID=1000
TZ=America/Chicago
DOCKERCONFDIR=/docker
DOCKERSTORAGEDIR=/mnt/data
DOCKERLOGGING_MAXFILE=10
DOCKERLOGGING_MAXSIZE=200k
QBITTORRENT_PORT=8090
SABNZBD_PORT=8080
VPN_SERVICE_PROVIDER=private internet access
VPN_TYPE=openvpn
OPENVPN_USER=p1708819
OPENVPN_PASSWORD=fEkdWZq44k
SERVER_CITIES=Netherlands
EOF
fi

#########################################
# 🚀 START CONTAINERS
#########################################

echo "🐳 Starting containers..."
docker compose up -d

#########################################

echo "🎉 FULL SETUP COMPLETE!"
echo "📁 NFS mounted at: $MOUNT_POINT"
echo "🐳 Arr stack running in: $INSTALL_DIR"
echo "⚠️ You may need to log out/in for Docker group changes."
