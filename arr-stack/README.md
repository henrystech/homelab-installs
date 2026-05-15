# Arr Stack Guided Installer

This folder contains a guided installer for a Docker-based homelab media stack on Ubuntu/Debian Linux servers.

The installer asks for your local values, can mount NAS storage over NFS, writes them to `/docker/.env` by default, copies or downloads `docker-compose.yaml`, and starts the stack with Docker Compose.

## Services

- Gluetun VPN gateway
- qBittorrent
- SABnzbd
- Prowlarr
- Radarr
- Sonarr anime
- Lidarr
- File Browser
- Custom Docker bridge network named `skynet`

## Quick Install

Run this on the machine that will host the containers:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/arr-stack/arr-stack.sh | sudo bash
```

The installer is interactive. It installs Linux dependencies and then prompts for values such as:

- NAS IP address
- NAS NFS export path
- local mount point
- Docker config directory
- media storage directory
- PUID, PGID, and timezone
- app ports
- VPN provider, username, password, and region

## Clone And Run

```bash
git clone https://github.com/henrystech/homelab-installs.git
cd homelab-installs/arr-stack
chmod +x arr-stack.sh
sudo ./arr-stack.sh
```

When run from a clone, the installer uses the local `docker-compose.yaml`. When run through `curl | bash`, it downloads the Compose file from GitHub.

## What It Does

Use this when the stack runs on an Ubuntu/Debian server or mini PC. The installer can:

- install NFS client packages
- install Docker if missing
- install the Docker Compose plugin if missing
- optionally mount storage from a NAS using NFS
- create app/config folders
- start the stack on the `skynet` Docker network

## Generated Files

By default the installer creates:

```text
/docker/docker-compose.yaml
/docker/.env
/docker/gluetun/config
/docker/qbittorrent/config
/docker/sabnzbd/config
/docker/prowlarr/config
/docker/radarr/config
/docker/sonarr-anime/config
/docker/lidarr/config
/docker/filebrowser/config
/docker/filebrowser/database
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

## Installer Choices Explained

- `Mount storage from a NAS over NFS?`: choose yes when your media lives on a NAS and this Ubuntu server should mount it.
- `NAS IP address`: the IP address of the NAS that exports the shared folder.
- `NAS export path`: the NFS path shared by the NAS, such as `/volume1/data`.
- `Local mount point`: where Ubuntu mounts that share, commonly `/mnt/data`.
- `NFS version`: the NFS protocol version. Version `4` is a good default.
- `Docker install/config directory`: where `docker-compose.yaml`, `.env`, and app folders are stored.
- `Container config directory`: the parent folder for app folders like `gluetun/config`, `radarr/config`, and `qbittorrent/config`.
- `Media storage directory`: the path mounted into media apps as `/data`.
- `PUID` and `PGID`: the Linux user and group IDs that should own files created by the containers.
- `Timezone`: the timezone passed into containers, such as `America/Chicago`.
- `Docker log max files` and `Docker log max size`: limits for container JSON logs.
- App ports: the host ports used to reach each web UI.
- VPN provider/type/user/password: the provider details Gluetun uses to start the VPN tunnel.
- `VPN server regions`: the provider region for Gluetun, such as `Netherlands` for Private Internet Access.
- `File Browser root directory`: the folder File Browser exposes in its web UI.

## Notes

- Rotate any credentials that were previously committed to a public repo.
- File Browser is configured to expose the selected media storage directory, not the whole server filesystem.
- Prowlarr, Radarr, Sonarr anime, and Lidarr use LinuxServer images with Theme Park's `overseerr` theme mod.
- qBittorrent and SABnzbd share Gluetun's network namespace so their traffic goes through the VPN.
- Gluetun has a 30-second healthcheck startup grace period.
- Other containers wait for Gluetun to become healthy before starting.
- Other containers join the named `skynet` bridge network.
- The installer currently automates package installation only for Ubuntu/Debian hosts that use `apt-get`.
- For Synology or UGREEN NAS installs, use the sibling `arr-stacknas` installer instead.
