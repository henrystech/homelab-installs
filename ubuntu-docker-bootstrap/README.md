# Ubuntu Docker Bootstrap

This folder contains a guided Ubuntu/Debian bootstrap script for preparing a fresh server to run Docker Compose stacks.

Use this before installing stacks such as `arr-stack`, `arr-stacklite`, `backup-stack`, or `monitoring-stack`.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/ubuntu-docker-bootstrap/ubuntu-docker-bootstrap.sh | sudo bash
```

## What It Does

The script prepares a clean Ubuntu/Debian server with the basics most homelab Docker hosts need:

- installs useful packages like `curl`, `git`, `nano`, `htop`, `jq`, and `unzip`
- installs Docker Engine from Docker's official apt repository
- installs the Docker Compose plugin
- creates a Docker root folder, normally `/docker`
- creates a shared Docker network, normally `skynet`
- optionally installs unattended security updates
- optionally installs Fail2ban for basic SSH protection
- writes a small summary file at `/docker/bootstrap-summary.txt`

## Installer Choices Explained

- `Docker root folder`: the parent folder where future stacks can store Compose files, `.env` files, and app config folders. The default is `/docker`.
- `Default Docker network name`: the shared bridge network containers can use to talk to each other. The default is `skynet`.
- `Install unattended security updates?`: installs Ubuntu/Debian automatic security updates so the server receives important patches.
- `Install Fail2ban for basic SSH protection?`: installs Fail2ban, which watches login failures and can block repeated bad login attempts.

## Notes

- This script is for Ubuntu/Debian servers, not Synology, UGREEN, Unraid, or Proxmox itself.
- It does not deploy application containers by itself. It prepares the host so other installer folders can deploy containers cleanly.
- If the installer adds your user to the `docker` group, log out and back in before running Docker commands without `sudo`.
