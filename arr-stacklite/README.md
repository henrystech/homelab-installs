# Arr Stack Lite Guided Installer

This folder contains a lighter Ubuntu/Debian installer for the Arr Stack. It keeps the management apps and File Browser, but does not install Gluetun, qBittorrent, or SABnzbd.

Use this version when you already have download clients elsewhere, do not need the VPN container, or want a simpler stack.

## Services

- Prowlarr
- Radarr
- Sonarr anime
- Lidarr
- File Browser
- Custom Docker bridge network named `skynet`

## Quick Install

Run this on the Ubuntu/Debian machine that will host the containers:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/arr-stacklite/arr-stacklite.sh | sudo bash
```

The installer is interactive. It installs Linux dependencies and then prompts for values such as:

- optional NAS NFS mount settings
- Docker config directory
- media storage directory
- PUID, PGID, and timezone
- app ports

## Clone And Run

```bash
git clone https://github.com/henrystech/homelab-installs.git
cd homelab-installs/arr-stacklite
chmod +x arr-stacklite.sh
sudo ./arr-stacklite.sh
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
/docker/prowlarr/config
/docker/radarr/config
/docker/sonarr-anime/config
/docker/lidarr/config
/docker/filebrowser/config
/docker/filebrowser/database
```

The `.env` file is machine-specific, so it should not be committed to GitHub.

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
- `Docker install/config directory`: where `docker-compose.yaml`, `.env`, and app config folders are stored.
- `Container config directory`: the parent folder for app folders like `radarr/config` and `prowlarr/config`.
- `Media storage directory`: the path mounted into Radarr, Sonarr, Lidarr, and related apps as `/data`.
- `PUID` and `PGID`: the Linux user and group IDs that should own files created by the containers.
- `Timezone`: the timezone passed into containers, such as `America/Chicago`.
- `Docker log max files` and `Docker log max size`: limits for container JSON logs.
- App ports: the host ports used to reach each web UI.
- `File Browser root directory`: the folder File Browser exposes in its web UI.

## Notes

- This lite stack does not include a VPN gateway or download clients.
- File Browser is configured to expose the selected media storage directory, not the whole server filesystem.
- Prowlarr, Radarr, Sonarr anime, and Lidarr use LinuxServer images with Theme Park's `overseerr` theme mod.
- Containers join the named `skynet` bridge network.
