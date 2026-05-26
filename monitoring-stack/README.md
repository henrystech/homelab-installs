# Monitoring Stack Guided Installer

This folder installs a small monitoring stack for a Docker host. It gives beginners two simple views: service uptime checks and container logs.

## Services

- Uptime Kuma
- Dozzle
- Custom Docker bridge network named `skynet`

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/monitoring-stack/monitoring-stack.sh | sudo bash
```

## What It Does

The installer:

- checks that Docker Compose is available
- asks where to install the stack
- asks which ports to use
- creates the Uptime Kuma data folder
- writes a private `.env` file
- starts the monitoring containers

## Generated Files

```text
/docker/monitoring-stack/docker-compose.yaml
/docker/monitoring-stack/.env
/docker/monitoring-stack/uptime-kuma/data
```

## Installer Choices Explained

- `Stack install directory`: where this stack's Compose file and `.env` file live.
- `Timezone`: the timezone passed into the containers.
- `Container config directory`: where app data is stored.
- `Uptime Kuma port`: the browser port for uptime checks and notifications.
- `Dozzle logs port`: the browser port for reading Docker container logs.

## Learning Notes

Uptime Kuma answers "is this service reachable?" Dozzle answers "what are my containers saying?" Together they are a friendly first monitoring setup before moving into larger tools like Prometheus or Grafana.
