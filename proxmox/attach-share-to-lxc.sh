#!/bin/bash

# ==========================================================
# Proxmox LXC Bind Mount Scripts
# Attaches a host folder to an LXC container persistently
# ==========================================================

set -e

# ---- USER VARIABLES ----
CONTAINER_ID="101"                 # Change to your LXC ID
HOST_SHARE="/mnt/shared-data"      # Folder on Proxmox host
CONTAINER_MOUNT="/mnt/shared"      # Folder inside container
MP_INDEX="0"                       # Mount point index (mp0, mp1, mp2...)
# ------------------------

echo "🔍 Checking if container exists..."
pct status $CONTAINER_ID > /dev/null

echo "📁 Ensuring host directory exists..."
mkdir -p "$HOST_SHARE"

echo "🛑 Stopping container if running..."
pct stop $CONTAINER_ID || true

echo "🔧 Creating mount point inside container config..."

# Remove old mount if exists
sed -i "/^mp$MP_INDEX:/d" /etc/pve/lxc/$CONTAINER_ID.conf

# Add bind mount
echo "mp$MP_INDEX: $HOST_SHARE,mp=$CONTAINER_MOUNT" >> /etc/pve/lxc/$CONTAINER_ID.conf

echo "📦 Creating mount directory inside container..."
pct start $CONTAINER_ID
pct exec $CONTAINER_ID -- mkdir -p "$CONTAINER_MOUNT"

echo "🔄 Restarting container..."
pct restart $CONTAINER_ID

echo "✅ Done!"
echo "Your host folder:"
echo "   $HOST_SHARE"
echo "is now mounted inside container:"
echo "   $CONTAINER_MOUNT"
echo ""
echo "✔ This will auto-mount every time the container reboots."