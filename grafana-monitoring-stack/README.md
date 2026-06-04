# Grafana Monitoring Stack Guided Installer

This folder installs a deeper monitoring stack for a Docker host.

Use this when Uptime Kuma and Dozzle are not enough and users want dashboards, host metrics, container metrics, and searchable container logs.

## Services

- Grafana
- Prometheus
- Node Exporter
- cAdvisor
- Loki
- Grafana Alloy
- Custom Docker bridge network named `skynet`

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/grafana-monitoring-stack/grafana-monitoring-stack.sh | sudo bash
```

## What Each Piece Does

- Grafana is the web UI where dashboards and logs are viewed.
- Prometheus stores and queries time-series metrics.
- Node Exporter exposes Linux host metrics such as CPU, memory, disk, and network.
- cAdvisor exposes Docker container resource metrics.
- Loki stores logs.
- Grafana Alloy collects Docker container logs and sends them to Loki.

## What It Does

The installer:

- checks that Docker Compose is available
- asks where to install the stack
- asks which ports to use
- asks for the Grafana admin username and password
- copies Prometheus, Loki, Alloy, and Grafana provisioning config
- creates persistent data folders
- writes a private `.env` file
- starts the stack

## Generated Files

```text
/opt/homelab/grafana-monitoring-stack/docker-compose.yaml
/opt/homelab/grafana-monitoring-stack/.env
/opt/homelab/grafana-monitoring-stack/config/prometheus/prometheus.yml
/opt/homelab/grafana-monitoring-stack/config/loki/loki-config.yaml
/opt/homelab/grafana-monitoring-stack/config/alloy/config.alloy
/opt/homelab/grafana-monitoring-stack/config/grafana/provisioning
/opt/homelab/grafana-monitoring-stack/config/grafana/dashboards
/opt/homelab/grafana-monitoring-stack/grafana/data
/opt/homelab/grafana-monitoring-stack/prometheus/data
/opt/homelab/grafana-monitoring-stack/loki/data
/opt/homelab/grafana-monitoring-stack/alloy/data
```

## Installer Choices Explained

- `Stack install directory`: where this stack's Compose file, `.env`, and config files live.
- `Timezone`: the timezone passed into Grafana.
- `Container config/data directory`: where persistent data is stored.
- `Grafana web UI port`: the browser port for Grafana.
- `Prometheus web UI port`: the browser port for Prometheus.
- `Loki web/API port`: the port used for Loki readiness checks and API access.
- `Grafana Alloy web UI port`: the port for Alloy's graph/debug UI.
- `cAdvisor web UI port`: the port for container metrics and cAdvisor's basic UI.
- `Node Exporter metrics port`: the port for Linux host metrics.
- `Grafana admin username`: the first Grafana admin user.
- `Grafana admin password`: the first Grafana admin password. This is written only to the local `.env` file.

## After Install

Open Grafana at:

```text
http://SERVER-IP:3004
```

The installer provisions:

- a Prometheus data source
- a Loki data source
- a starter `Homelab Overview` dashboard

Good community dashboards to import later:

- Node Exporter Full: dashboard ID `1860`
- Docker and cAdvisor dashboards: search Grafana dashboards for `cAdvisor`

## Learning Notes

Uptime Kuma answers "is the service reachable?" Grafana plus Prometheus answers "what is the server doing over time?"

Prometheus pulls metrics from exporters. Node Exporter talks about the Linux host. cAdvisor talks about Docker containers.

Loki stores logs. Alloy is the collector that reads Docker logs and sends them to Loki. Grafana can show metrics and logs side by side.

The Docker socket is mounted read-only into Alloy so it can discover container logs. This is useful, but users should understand that the Docker socket is sensitive and this stack should not be exposed publicly without authentication.
