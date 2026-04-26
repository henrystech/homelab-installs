#!/bin/bash

set -e

echo "🚀 Starting Synology NFS Mount Setup..."

#########################################
# 🔧 CONFIGURATION
#########################################

NAS_IP="192.168.1.10"
NAS_EXPORT="/volume1/data"
MOUNT_POINT="/mnt/data"
NFS_VERSION="4"

# User that should own the mount (change if needed)
LOCAL_USER="${SUDO_USER:-$(whoami)}"
LOCAL_UID=$(id -u "$LOCAL_USER")
LOCAL_GID=$(id -g "$LOCAL_USER")

#########################################

# Must run as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Please run as root (sudo ./install_synology_nfs.sh)"
   exit 1
fi

echo "📦 Installing NFS client packages..."
apt update
apt install -y nfs-common

echo "📁 Creating mount point..."
mkdir -p "$MOUNT_POINT"

echo "🔐 Setting mount point permissions..."
chown "$LOCAL_UID:$LOCAL_GID" "$MOUNT_POINT"
chmod 775 "$MOUNT_POINT"

echo "🔎 Testing connection to NAS..."
showmount -e "$NAS_IP" || {
    echo "❌ Unable to reach NAS or NFS not enabled."
    exit 1
}

echo "🔗 Mounting NFS share with read/write access..."
mount -t nfs -o vers=$NFS_VERSION,rw "$NAS_IP:$NAS_EXPORT" "$MOUNT_POINT"

echo "💾 Adding to /etc/fstab for automatic mounting..."
FSTAB_ENTRY="$NAS_IP:$NAS_EXPORT $MOUNT_POINT nfs defaults,_netdev,vers=$NFS_VERSION,rw 0 0"

if ! grep -qs "$NAS_IP:$NAS_EXPORT" /etc/fstab; then
    echo "$FSTAB_ENTRY" >> /etc/fstab
fi

echo "🔄 Applying mount..."
mount -a

echo "🔐 Re-applying ownership after mount..."
chown "$LOCAL_UID:$LOCAL_GID" "$MOUNT_POINT"

echo "✅ Verifying mount..."
df -h | grep "$MOUNT_POINT"

echo "🎉 Synology NFS share successfully mounted at $MOUNT_POINT"