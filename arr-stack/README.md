# Arr Stack Guided Installer

This folder contains a guided installer for a Docker-based homelab media stack. It is meant to be reusable on Ubuntu/Debian servers, generic Docker hosts, and NAS Docker hosts such as Synology or UGREEN.

The installer asks for your local values, writes them to `/docker/.env` by default, copies or downloads `docker-compose.yaml`, and starts the stack with Docker Compose.

## Services

- Gluetun VPN gateway
- qBittorrent
- SABnzbd
- Prowlarr
- Radarr
- Sonarr anime
- Sonarr TV
- Lidarr
- File Browser

## Quick Install

Run this on the machine that will host the containers:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/arr-stack/arr-stack.sh | sudo bash
```

The installer is interactive. It will ask where the containers are being installed and then prompt for values such as:

- NAS IP address
- NAS NFS export path
- local mount point
- Docker config directory
- media storage directory
- PUID, PGID, and timezone
- app ports
- VPN provider, username, password, and region/city

## Clone And Run

```bash
git clone https://github.com/henrystech/homelab-installs.git
cd homelab-installs/arr-stack
chmod +x arr-stack.sh
sudo ./arr-stack.sh
```

When run from a clone, the installer uses the local `docker-compose.yaml`. When run through `curl | bash`, it downloads the Compose file from GitHub.

## Install Modes

### Ubuntu/Debian Linux Server

Use this when the stack runs on a Linux server or mini PC. The installer can:

- install NFS client packages
- install Docker if missing
- install the Docker Compose plugin if missing
- optionally mount storage from a NAS using NFS

### Synology Or UGREEN NAS Docker Host

Use this when the containers run directly on the NAS. The installer skips Linux package installation and assumes Docker or Container Manager is already available.

### Generic Docker Host

Use this when Docker is already installed and you only want the installer to create the Compose folder, write `.env`, and start the stack.

## Generated Files

By default the installer creates:

```text
/docker/docker-compose.yaml
/docker/.env
```

The `.env` file is machine-specific and contains secrets, so it should not be committed to GitHub.

## Manual Start

If you want to start the stack later:

```bash
cd /docker
docker compose up -d
```

To stop it:

```bash
cd /docker
docker compose down
```

## Notes

- Rotate any credentials that were previously committed to a public repo.
- File Browser is configured to expose the selected media storage directory, not the whole server filesystem.
- The installer currently automates package installation only for Ubuntu/Debian hosts that use `apt-get`.
