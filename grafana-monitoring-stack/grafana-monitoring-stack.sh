#!/usr/bin/env bash

set -Eeuo pipefail

REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/henrystech/homelab-installs/main/grafana-monitoring-stack}"
INSTALL_DIR_DEFAULT="/opt/homelab/grafana-monitoring-stack"
COMPOSE_FILE_NAME="docker-compose.yaml"

log() {
  printf '\n==> %s\n' "$1"
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "Please run as root: sudo ./grafana-monitoring-stack.sh"
  fi

  if [[ ! -r /dev/tty ]]; then
    die "This guided installer needs an interactive terminal."
  fi
}

env_value() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\'/\\\'}"
  printf "'%s'" "$value"
}

prompt() {
  local label="$1"
  local default_value="${2:-}"
  local answer

  if [[ -n "$default_value" ]]; then
    printf '%s [%s]: ' "$label" "$default_value" >/dev/tty
    read -r answer </dev/tty
    printf '%s' "${answer:-$default_value}"
  else
    printf '%s: ' "$label" >/dev/tty
    read -r answer </dev/tty
    printf '%s' "$answer"
  fi
}

prompt_secret() {
  local label="$1"
  local answer

  printf '%s: ' "$label" >/dev/tty
  read -r -s answer </dev/tty
  printf '\n' >/dev/tty
  printf '%s' "$answer"
}

prompt_yes_no() {
  local label="$1"
  local default_value="${2:-Y}"
  local answer
  local suffix="y/N"

  if [[ "$default_value" =~ ^[Yy]$ ]]; then
    suffix="Y/n"
  fi

  while true; do
    printf '%s [%s]: ' "$label" "$suffix" >/dev/tty
    read -r answer </dev/tty
    answer="${answer:-$default_value}"
    case "$answer" in
      [Yy]|[Yy][Ee][Ss]) return 0 ;;
      [Nn]|[Nn][Oo]) return 1 ;;
      *) printf 'Please answer yes or no.\n' >/dev/tty ;;
    esac
  done
}

require_docker_compose() {
  if ! docker compose version >/dev/null 2>&1; then
    die "Docker Compose was not found. Run ubuntu-docker-bootstrap first or install Docker Compose."
  fi
}

copy_or_download_file() {
  local source_path="$1"
  local install_dir="$2"
  local script_dir
  local destination

  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P || pwd)"
  destination="$install_dir/$source_path"
  mkdir -p "$(dirname "$destination")"

  if [[ -f "$script_dir/$source_path" ]]; then
    install -m 0644 "$script_dir/$source_path" "$destination"
  else
    curl -fsSL "$REPO_RAW_URL/$source_path" -o "$destination"
  fi
}

copy_stack_files() {
  local install_dir="$1"
  local files=(
    "$COMPOSE_FILE_NAME"
    "config/prometheus/prometheus.yml"
    "config/loki/loki-config.yaml"
    "config/alloy/config.alloy"
    "config/grafana/provisioning/datasources/datasources.yaml"
    "config/grafana/provisioning/dashboards/dashboards.yaml"
    "config/grafana/dashboards/homelab-overview.json"
  )
  local file

  log "Installing Docker Compose and monitoring config files"
  mkdir -p "$install_dir"

  for file in "${files[@]}"; do
    copy_or_download_file "$file" "$install_dir"
  done
}

write_env_file() {
  local env_file="$1"

  if [[ -f "$env_file" ]] && ! prompt_yes_no "$env_file already exists. Replace it?" "N"; then
    return
  fi

  cat > "$env_file" <<ENVEOF
TZ=$(env_value "$TZ")
STACKDIR=$(env_value "$INSTALL_DIR")
DOCKERCONFDIR=$(env_value "$DOCKERCONFDIR")
GRAFANA_PORT=$(env_value "$GRAFANA_PORT")
PROMETHEUS_PORT=$(env_value "$PROMETHEUS_PORT")
LOKI_PORT=$(env_value "$LOKI_PORT")
ALLOY_PORT=$(env_value "$ALLOY_PORT")
CADVISOR_PORT=$(env_value "$CADVISOR_PORT")
NODE_EXPORTER_PORT=$(env_value "$NODE_EXPORTER_PORT")
GRAFANA_ADMIN_USER=$(env_value "$GRAFANA_ADMIN_USER")
GRAFANA_ADMIN_PASSWORD=$(env_value "$GRAFANA_ADMIN_PASSWORD")
ENVEOF

  chmod 600 "$env_file"
}

prepare_directories() {
  log "Preparing Grafana monitoring folders"
  mkdir -p \
    "$DOCKERCONFDIR/grafana/data" \
    "$DOCKERCONFDIR/prometheus/data" \
    "$DOCKERCONFDIR/loki/data" \
    "$DOCKERCONFDIR/alloy/data"

  chown -R 472:472 "$DOCKERCONFDIR/grafana" || true
  chown -R 65534:65534 "$DOCKERCONFDIR/prometheus" || true
  chown -R 10001:10001 "$DOCKERCONFDIR/loki" || true
}

require_root

log "Grafana Monitoring Stack guided installer"
require_docker_compose

INSTALL_DIR="$(prompt "Stack install directory" "$INSTALL_DIR_DEFAULT")"
TZ="$(prompt "Timezone" "$(timedatectl show -p Timezone --value 2>/dev/null || printf 'America/Chicago')")"
DOCKERCONFDIR="$(prompt "Container config/data directory" "$INSTALL_DIR")"
GRAFANA_PORT="$(prompt "Grafana web UI port" "3004")"
PROMETHEUS_PORT="$(prompt "Prometheus web UI port" "9090")"
LOKI_PORT="$(prompt "Loki web/API port" "3100")"
ALLOY_PORT="$(prompt "Grafana Alloy web UI port" "12345")"
CADVISOR_PORT="$(prompt "cAdvisor web UI port" "8083")"
NODE_EXPORTER_PORT="$(prompt "Node Exporter metrics port" "9100")"
GRAFANA_ADMIN_USER="$(prompt "Grafana admin username" "admin")"
GRAFANA_ADMIN_PASSWORD="$(prompt_secret "Grafana admin password")"

copy_stack_files "$INSTALL_DIR"
prepare_directories
write_env_file "$INSTALL_DIR/.env"

log "Starting Grafana Monitoring Stack"
docker compose --env-file "$INSTALL_DIR/.env" -f "$INSTALL_DIR/$COMPOSE_FILE_NAME" up -d

log "Grafana Monitoring Stack complete"
printf 'Grafana URL: http://SERVER-IP:%s\n' "$GRAFANA_PORT"
printf 'Prometheus URL: http://SERVER-IP:%s\n' "$PROMETHEUS_PORT"
printf 'Loki ready check: http://SERVER-IP:%s/ready\n' "$LOKI_PORT"
printf 'Alloy graph: http://SERVER-IP:%s/graph\n' "$ALLOY_PORT"
