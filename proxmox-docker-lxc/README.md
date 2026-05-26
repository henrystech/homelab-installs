# Proxmox Docker LXC Helper

This folder contains a guided helper that creates a Proxmox LXC container for running Docker Compose stacks.

Use this when you want Proxmox to host a dedicated lightweight container for Docker apps instead of installing Docker directly on the Proxmox host.

## Quick Install

Run this on the Proxmox host shell:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/proxmox-docker-lxc/proxmox-docker-lxc.sh | bash
```

If you are not already root:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/proxmox-docker-lxc/proxmox-docker-lxc.sh | sudo bash
```

## What It Does

The helper can:

- create an unprivileged LXC container
- enable `nesting` and `keyctl`, which Docker commonly needs inside LXC
- start the container
- optionally install Docker and the Docker Compose plugin inside the container
- create `/docker`
- create the `skynet` Docker network

## Installer Choices Explained

- `Container ID`: the Proxmox numeric ID for the new LXC.
- `Container hostname`: the name shown in Proxmox and inside the container.
- `Template volume`: the Proxmox template to use, such as a Debian 12 standard template.
- `Proxmox storage name`: where the LXC disk should live, such as `local-lvm`.
- `Disk size`: how much disk space to give the LXC.
- `CPU cores`: how many CPU cores the container can use.
- `Memory MB`: how much RAM the container can use.
- `Network bridge`: the Proxmox bridge, commonly `vmbr0`.
- `IP config`: use `dhcp` or a static value such as `192.168.1.50/24,gw=192.168.1.1`.
- `Container root password`: the root password for the new LXC.

## Notes

- The default template name may be different on your Proxmox host. Run `pveam update` and then `pveam available --section system` to find templates.
- This script asks for confirmation before creating the LXC.
- After the container is created, enter it with `pct enter CONTAINER_ID`.
