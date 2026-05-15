# NAS Arr Stack Guided Installer

This folder contains the NAS-focused installer for the Arr Stack. Use this version when the containers run directly on a Synology NAS, UGREEN NAS, or another NAS Docker host.

Unlike the Ubuntu installer, this script does not install Linux packages and does not configure NFS. It assumes the NAS already owns the storage path and already has Docker or Container Manager installed.

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

Run this from an SSH session on the NAS:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/arr-stacknas/arr-stacknas.sh | sudo bash
```

The installer asks for:

- NAS type, such as Synology or UGREEN
- Docker config directory, usually `/volume1/docker/arr-stack`
- NAS media storage directory, usually `/volume1/data`
- PUID, PGID, and timezone
- app ports
- VPN provider, username, password, and region

## Clone And Run

```bash
git clone https://github.com/henrystech/homelab-installs.git
cd homelab-installs/arr-stacknas
chmod +x arr-stacknas.sh
sudo ./arr-stacknas.sh
```

When run from a clone, the installer uses the local `docker-compose.yaml`. When run through `curl | bash`, it downloads the Compose file from GitHub.

## Defaults

The installer defaults to common Synology and UGREEN-style paths:

```text
/volume1/docker/arr-stack
/volume1/data
```

You can change these during the prompts if your NAS uses different shared-folder names, such as `/volume1/media` or `/volume2/data`.

## Generated Files

By default the installer creates:

```text
/volume1/docker/arr-stack/docker-compose.yaml
/volume1/docker/arr-stack/.env
/volume1/docker/arr-stack/gluetun/config
/volume1/docker/arr-stack/qbittorrent/config
/volume1/docker/arr-stack/sabnzbd/config
/volume1/docker/arr-stack/prowlarr/config
/volume1/docker/arr-stack/radarr/config
/volume1/docker/arr-stack/sonarr-anime/config
/volume1/docker/arr-stack/lidarr/config
/volume1/docker/arr-stack/filebrowser/config
/volume1/docker/arr-stack/filebrowser/database
```

The `.env` file is machine-specific and contains secrets, so it should not be committed to GitHub.

## Manual Start

If you want to start the stack later:

```bash
cd /volume1/docker/arr-stack
docker compose up -d
```

On NAS systems with the older Compose binary:

```bash
cd /volume1/docker/arr-stack
docker-compose up -d
```

## Installer Choices Explained

- `NAS type`: selects default paths for Synology, UGREEN, or another NAS Docker host.
- `Docker install/config directory`: where `docker-compose.yaml`, `.env`, and app folders are stored.
- `Container config directory`: the parent folder for app folders like `gluetun/config`, `radarr/config`, and `qbittorrent/config`.
- `NAS media storage directory`: the NAS folder mounted into media apps as `/data`.
- `PUID` and `PGID`: the NAS user and group IDs that should own files created by the containers.
- `Timezone`: the timezone passed into containers, such as `America/Chicago`.
- `Docker log max files` and `Docker log max size`: limits for container JSON logs.
- App ports: the host ports used to reach each web UI.
- VPN provider/type/user/password: the provider details Gluetun uses to start the VPN tunnel.
- `VPN server regions`: the provider region for Gluetun, such as `Netherlands` for Private Internet Access.
- `File Browser root directory`: the folder File Browser exposes in its web UI.

## Notes

- Install Docker, Container Manager, or your NAS vendor's Docker package before running this script.
- File Browser is configured to expose the selected media storage directory, not the whole NAS filesystem.
- Prowlarr, Radarr, Sonarr anime, and Lidarr use LinuxServer images with Theme Park's `overseerr` theme mod.
- qBittorrent and SABnzbd share Gluetun's network namespace so their traffic goes through the VPN.
- Gluetun has a 30-second healthcheck startup grace period.
- Other containers wait for Gluetun to become healthy before starting.
- Other containers join the named `skynet` bridge network.
