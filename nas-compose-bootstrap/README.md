# NAS Compose Bootstrap

This folder creates a small Docker Compose starter project for Synology NAS, UGREEN NAS, or another NAS that already has Docker/Container Manager installed.

Use this when the NAS itself is the Docker host and you want a simple, readable Compose project to learn from.

## Services

- Uptime Kuma
- File Browser
- Custom Docker bridge network named `skynet`

## Quick Install

Run this from the NAS terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/nas-compose-bootstrap/nas-compose-bootstrap.sh | bash
```

## What It Does

The helper:

- asks where to create the Compose project
- asks where app configuration should live
- asks which NAS folder File Browser should expose
- writes a `.env` file
- writes a `docker-compose.yaml`
- creates the appdata folders
- optionally starts the stack if Docker Compose is available

## Generated Files

Default Synology-style layout:

```text
/volume1/docker/homelab-compose/docker-compose.yaml
/volume1/docker/homelab-compose/.env
/volume1/docker/homelab-compose/uptime-kuma/data
/volume1/docker/homelab-compose/filebrowser/database
/volume1/docker/homelab-compose/filebrowser/config
```

## Installer Choices Explained

- `Compose project folder`: where the Compose project files are created.
- `Timezone`: the timezone passed into containers.
- `Appdata/config folder`: where app data is stored.
- `NAS folder exposed in File Browser`: the NAS path shown inside File Browser.
- `PUID` and `PGID`: the user and group IDs containers should use when writing files.
- `Uptime Kuma port`: the browser port for uptime checks.
- `File Browser port`: the browser port for File Browser.
- `Start the Compose project now?`: starts the containers from the terminal if Docker Compose is available.

## Notes

- This helper does not install Docker. Synology and UGREEN users should install Container Manager or Docker from the NAS app center first.
- The existing `arr-stacknas` folder is still the dedicated NAS media stack. This folder is a smaller starter project.
