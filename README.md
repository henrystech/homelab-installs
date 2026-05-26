# Homelab Installs

Guided installers for repeatable homelab Docker stacks. Each folder is meant to be self-contained with its own install script, Docker Compose file, example environment file, and detailed README.

## Installers

| Folder | Main script | Purpose |
| --- | --- | --- |
| `arr-stack` | `arr-stack.sh` | Full Ubuntu/Debian Arr stack with optional NFS mounting, Gluetun VPN, qBittorrent, SABnzbd, Prowlarr, Radarr, Sonarr anime, Lidarr, and File Browser. |
| `arr-stacknas` | `arr-stacknas.sh` | NAS-focused Arr stack for Synology, UGREEN, or another NAS Docker host. This version skips the NFS setup because the NAS already provides local storage. |
| `arr-stacklite` | `arr-stacklite.sh` | Lightweight Ubuntu/Debian Arr stack with optional NFS mounting. This version does not include Gluetun, qBittorrent, SABnzbd, or VPN credential prompts. |
| `backup-stack` | `backup-stack.sh` | Kopia backup stack for backing up important homelab folders such as `/docker`, app config folders, Compose files, and `.env` files. |
| `monitoring-stack` | `monitoring-stack.sh` | Small monitoring stack with Uptime Kuma for uptime checks and Dozzle for Docker container logs. |
| `nas-compose-bootstrap` | `nas-compose-bootstrap.sh` | Synology/UGREEN NAS Compose starter that creates a small project with Uptime Kuma and File Browser. |
| `proxmox-docker-lxc` | `proxmox-docker-lxc.sh` | Proxmox helper that creates a Docker-ready LXC and can install Docker Compose inside it. |
| `proxmox-post-install` | `proxmox-post-install.sh` | Proxmox first-day helper for repositories, useful tools, and optional package updates. |
| `ubuntu-docker-bootstrap` | `ubuntu-docker-bootstrap.sh` | Ubuntu/Debian bootstrap script that installs Docker from the official apt repository, creates `/docker`, and creates the `skynet` network. |
| `unraid-compose-helper` | `unraid-compose-helper.sh` | Unraid-friendly Compose helper that creates a small starter project users can import or run with Compose Manager. |

## Quick Install

Full Ubuntu/Debian stack:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/arr-stack/arr-stack.sh | sudo bash
```

NAS stack:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/arr-stacknas/arr-stacknas.sh | sudo bash
```

Lite Ubuntu/Debian stack:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/arr-stacklite/arr-stacklite.sh | sudo bash
```

Ubuntu/Debian Docker bootstrap:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/ubuntu-docker-bootstrap/ubuntu-docker-bootstrap.sh | sudo bash
```

Backup stack:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/backup-stack/backup-stack.sh | sudo bash
```

Monitoring stack:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/monitoring-stack/monitoring-stack.sh | sudo bash
```

NAS Compose starter:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/nas-compose-bootstrap/nas-compose-bootstrap.sh | bash
```

Proxmox post-install helper:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/proxmox-post-install/proxmox-post-install.sh | bash
```

Proxmox Docker LXC helper:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/proxmox-docker-lxc/proxmox-docker-lxc.sh | bash
```

Unraid Compose helper:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/unraid-compose-helper/unraid-compose-helper.sh | bash
```

## Folder Convention

Every installer folder should include:

- `README.md` with detailed instructions for that specific stack.
- An install script, usually named after the folder.
- `docker-compose.yaml` for container stacks, when the folder deploys containers.
- `.env.example` for container stacks, showing the variables the script will ask for or generate.

## Maintenance Rule

Whenever a new installer or script folder is added, update this root `README.md` in the same change. Add the folder name, main script, short purpose, quick install command, and any major assumptions or exclusions.
