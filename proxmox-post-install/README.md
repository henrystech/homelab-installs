# Proxmox Post Install Helper

This folder contains a guided helper for a fresh Proxmox VE host. It focuses on common first-day setup tasks and explains what it changes.

## Quick Install

Run this directly on the Proxmox host shell:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/proxmox-post-install/proxmox-post-install.sh | bash
```

If you are not already root:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/proxmox-post-install/proxmox-post-install.sh | sudo bash
```

## What It Does

The script can:

- verify it is running on Proxmox VE
- disable enterprise apt repositories that require a subscription
- enable the Proxmox no-subscription repository
- install useful command-line admin tools
- optionally update Proxmox packages

## Installer Choices Explained

- `Disable enterprise repositories that require a subscription?`: comments out enterprise repository entries so apt does not fail on a host without a paid subscription.
- `Enable the Proxmox no-subscription repository?`: adds the public Proxmox repository commonly used by homelab users.
- `Install useful admin tools?`: installs tools like `htop`, `iotop`, `jq`, `tmux`, and `net-tools`.
- `Update Proxmox packages now?`: runs a package upgrade. The default is no so users can choose when they want to update.

## Notes

- This script does not remove the Proxmox web UI subscription notice.
- This script does not create VMs or containers. Use `proxmox-docker-lxc` for a guided Docker LXC.
- Always read prompts carefully because this script changes host apt repository configuration.
