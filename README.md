# Homelab Installs

Guided installers for repeatable homelab Docker stacks. Each folder is meant to be self-contained with its own install script, Docker Compose file, example environment file, and detailed README.

## Installers

| Folder | Main script | Purpose |
| --- | --- | --- |
| `arr-stack` | `arr-stack.sh` | Full Ubuntu/Debian Arr stack with optional NFS mounting, Gluetun VPN, qBittorrent, SABnzbd, Prowlarr, Radarr, Sonarr anime, Lidarr, and File Browser. |
| `arr-stacknas` | `arr-stacknas.sh` | NAS-focused Arr stack for Synology, UGREEN, or another NAS Docker host. This version skips the NFS setup because the NAS already provides local storage. |
| `arr-stacklite` | `arr-stacklite.sh` | Lightweight Ubuntu/Debian Arr stack with optional NFS mounting. This version does not include Gluetun, qBittorrent, SABnzbd, or VPN credential prompts. |

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

## Folder Convention

Every installer folder should include:

- `README.md` with detailed instructions for that specific stack.
- An install script, usually named after the folder.
- `docker-compose.yaml` for the containers used by that stack.
- `.env.example` showing the variables the script will ask for or generate.

## Maintenance Rule

Whenever a new installer or script folder is added, update this root `README.md` in the same change. Add the folder name, main script, short purpose, quick install command, and any major assumptions or exclusions.
