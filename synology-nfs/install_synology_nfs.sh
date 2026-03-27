#!/bin/bash

set -e

echo "🚀 Starting Synology NFS Mount Setup..."

#########################################
# 🔧 EDIT THESE VARIABLES
#########################################

NAS_IP="192.168.1.10"                 # Synology IP address
NAS_EXPORT="/volume1/data"           # NFS path from Synology
MOUNT_POINT="/mnt/data"            # Where Ubuntu will mount it
NFS_VERSION="4"                        # Recommended: 4

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

echo "🔎 Testing connection to NAS..."
showmount -e "$NAS_IP" || {
    echo "❌ Unable to reach NAS or NFS not enabled."
    exit 1
}

echo "🔗 Mounting NFS share..."
mount -t nfs -o vers=$NFS_VERSION "$NAS_IP:$NAS_EXPORT" "$MOUNT_POINT"

echo "💾 Adding to /etc/fstab for automatic mounting..."
FSTAB_ENTRY="$NAS_IP:$NAS_EXPORT $MOUNT_POINT nfs defaults,_netdev,vers=$NFS_VERSION 0 0"

if ! grep -qs "$NAS_IP:$NAS_EXPORT" /etc/fstab; then
    echo "$FSTAB_ENTRY" >> /etc/fstab
fi

echo "✅ Verifying mount..."
mount -a

echo "🎉 Synology NFS share successfully mounted at $MOUNT_POINT"
df -h | grep "$MOUNT_POINT"