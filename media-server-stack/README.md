# Media Server Stack Guided Installer

This folder installs Jellyfin and Jellyseerr.

Use this with the existing Arr stacks when users want a media playback server and a request interface.

## Services

- Jellyfin
- Jellyseerr
- Custom Docker bridge network named `skynet`

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/media-server-stack/media-server-stack.sh | sudo bash
```

## What It Does

The installer:

- checks that Docker Compose is available
- asks where to install the stack
- asks where media files live
- creates movie, TV, and anime folders
- writes a private `.env` file
- starts Jellyfin and Jellyseerr

## Generated Files

```text
/opt/homelab/media-server-stack/docker-compose.yaml
/opt/homelab/media-server-stack/.env
/opt/homelab/media-server-stack/jellyfin/config
/opt/homelab/media-server-stack/jellyfin/cache
/opt/homelab/media-server-stack/jellyseerr/config
/mnt/data/media/movies
/mnt/data/media/tv
/mnt/data/media/anime
```

## Installer Choices Explained

- `Stack install directory`: where this stack's Compose file and `.env` file live.
- `Timezone`: the timezone passed into containers.
- `PUID` and `PGID`: the user and group IDs containers should use for files.
- `Container config directory`: where Jellyfin and Jellyseerr config files are stored.
- `Media directory`: where media files live on the host. This is mounted into Jellyfin as `/data/media`.
- `Jellyfin port`: the browser port for Jellyfin.
- `Jellyseerr port`: the browser port for Jellyseerr.

## Learning Notes

Jellyfin is the media server. It scans folders and streams movies, shows, music, and anime.

Jellyseerr is the request layer. It helps users request media and connect that request flow to Radarr and Sonarr.

The media directory is mounted read-only into Jellyfin because Jellyfin usually only needs to read media. Tools like Radarr and Sonarr should be the apps organizing and writing media files.
