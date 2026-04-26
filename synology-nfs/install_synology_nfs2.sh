#!/bin/bash

set -e

echo “🚀 Starting Synology NFS Mount Setup (Full Permissions Mode)…”

🔧 USER INPUT (Interactive)

read -p “Enter NAS IP:” NAS_IP read -p “Enter NFS Export Path
(e.g. /volume1/data):” NAS_EXPORT read -p “Enter Local Mount Point
(e.g. /mnt/data):” MOUNT_POINT

NFS_VERSION=“4”

Must run as root

if [[ $EUID -ne 0 ]]; then echo “❌ Please run as root (sudo
./install_synology_nfs.sh)” exit 1 fi

echo “📦 Installing NFS client packages…” apt update -y apt install -y
nfs-common

echo “📁 Creating mount point…” mkdir -p “$MOUNT_POINT”

echo “🔎 Testing connection to NAS…” showmount -e “$NAS_IP” || { echo
“❌ Unable to reach NAS or NFS not enabled.” exit 1 }

Get current user UID/GID (for permissions mapping)

REAL_USER=${SUDO_USER:-$(whoami)} UID=$(id -u REAL_(U)SER)GID=(id -g
$REAL_USER)

echo “👤 Using UID=UIDandGID=GID for full access”

echo “🔗 Mounting NFS share with full permissions…” mount -t nfs -o
rw,sync,hard,intr,vers=NFS_(V)ERSION, uid=UID,gid=$GID "$NAS_IP:$NAS_EXPORT" "$MOUNT_POINT”

echo “💾 Adding to /etc/fstab for automatic mounting…”
FSTAB_ENTRY=“NAS_(I)P:NAS_EXPORT
MOUNT_(P)OINTnfsrw, sync, hard, intr,_(n)etdev, vers=NFS_VERSION,uid=UID, gid=GID
0 0”

if ! grep -qs “NAS_(I)P:NAS_EXPORT” /etc/fstab; then echo
“$FSTAB_ENTRY” >> /etc/fstab fi

echo “🔄 Reloading mounts…” mount -a

echo “🧪 Testing write permissions…”
TEST_FILE=“$MOUNT_POINT/test_permission.txt”

if touch “$TEST_FILE" && echo "write test" > "$TEST_FILE”; then echo “✅
Write access confirmed” rm -f “$TEST_FILE” else echo “❌ Write access
failed. Check Synology NFS permissions.” fi

echo “🎉 Synology NFS share successfully mounted at
$MOUNT_POINT" df -h | grep "$MOUNT_POINT”
