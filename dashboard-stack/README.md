# Dashboard Stack Guided Installer

This folder installs Homepage, a clean dashboard for linking to homelab services.

Use this when users have several apps running and want one place to open everything.

## Services

- Homepage
- Custom Docker bridge network named `skynet`

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/dashboard-stack/dashboard-stack.sh | sudo bash
```

## What It Does

The installer:

- checks that Docker Compose is available
- asks where to install the stack
- creates starter Homepage config files
- writes a private `.env` file
- starts the Homepage container

## Generated Files

```text
/opt/homelab/dashboard-stack/docker-compose.yaml
/opt/homelab/dashboard-stack/.env
/opt/homelab/dashboard-stack/homepage/config/settings.yaml
/opt/homelab/dashboard-stack/homepage/config/services.yaml
/opt/homelab/dashboard-stack/homepage/config/bookmarks.yaml
/opt/homelab/dashboard-stack/homepage/config/widgets.yaml
```

## Installer Choices Explained

- `Stack install directory`: where this stack's Compose file and `.env` file live.
- `Timezone`: the timezone passed into the container.
- `PUID` and `PGID`: the user and group IDs that should own generated config files.
- `Container config directory`: where Homepage config files are stored.
- `Homepage port`: the browser port for the dashboard.
- `Allowed dashboard hosts`: hostnames or IPs Homepage is allowed to respond to.

## Learning Notes

A dashboard is not the same as monitoring. A dashboard gives users a friendly launch page. Monitoring tells users whether services are healthy.

This Compose file mounts the Docker socket read-only so Homepage can discover containers. That is convenient, but users should understand that the Docker socket is sensitive and should not be exposed publicly.
