# attach-share-to-lxc.sh script
Since you're running Proxmox and working with LXC containers, here’s a production-ready bash script that:
 - Mounts a host directory on Proxmox
 - Binds it into an LXC container
 - Ensures it persists after container reboots
 - Works for both privileged and unprivileged containers
 - This uses Proxmox’s native bind mount (mpX) feature — which is the correct and persistent method.

 - Download attach-share-to-lxc.sh script directly:
     ```bash
     curl -fsSL https://gitea.henrystech.dev/l0rdmusash1/bash-installs/raw/main/proxmox/attach-share-to-lxc.sh | bash
     ```
# 📌 How It Works
Proxmox stores LXC config in: