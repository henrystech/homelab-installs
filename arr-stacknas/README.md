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
- VPN provider, username, password, and region/city

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

## Notes

- Install Docker, Container Manager, or your NAS vendor's Docker package before running this script.
- File Browser is configured to expose the selected media storage directory, not the whole NAS filesystem.
- qBittorrent and SABnzbd share Gluetun's network namespace so their traffic goes through the VPN.
- Other containers join the named `skynet` bridge network.
