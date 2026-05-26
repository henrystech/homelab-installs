#!/usr/bin/env bash

set -Eeuo pipefail

REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/henrystech/homelab-installs/main/monitoring-stack}"
INSTALL_DIR_DEFAULT="/docker/monitoring-stack"
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
    die "Please run as root: sudo ./monitoring-stack.sh"
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

copy_or_download_compose() {
  local install_dir="$1"
  local script_dir

  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P || pwd)"

  log "Installing Docker Compose file"
  mkdir -p "$install_dir"

  if [[ -f "$script_dir/$COMPOSE_FILE_NAME" ]]; then
    install -m 0644 "$script_dir/$COMPOSE_FILE_NAME" "$install_dir/$COMPOSE_FILE_NAME"
  else
    curl -fsSL "$REPO_RAW_URL/$COMPOSE_FILE_NAME" -o "$install_dir/$COMPOSE_FILE_NAME"
  fi
}

write_env_file() {
  local env_file="$1"

  if [[ -f "$env_file" ]] && ! prompt_yes_no "$env_file already exists. Replace it?" "N"; then
    return
  fi

  cat > "$env_file" <<ENVEOF
TZ=$(env_value "$TZ")
DOCKERCONFDIR=$(env_value "$DOCKERCONFDIR")
UPTIME_KUMA_PORT=$(env_value "$UPTIME_KUMA_PORT")
DOZZLE_PORT=$(env_value "$DOZZLE_PORT")
ENVEOF

  chmod 600 "$env_file"
}

prepare_directories() {
  log "Preparing monitoring folders"
  mkdir -p "$DOCKERCONFDIR/uptime-kuma/data"
}

require_root

log "Monitoring Stack guided installer"
require_docker_compose

INSTALL_DIR="$(prompt "Stack install directory" "$INSTALL_DIR_DEFAULT")"
TZ="$(prompt "Timezone" "$(timedatectl show -p Timezone --value 2>/dev/null || printf 'America/Chicago')")"
DOCKERCONFDIR="$(prompt "Container config directory" "$INSTALL_DIR")"
UPTIME_KUMA_PORT="$(prompt "Uptime Kuma port" "3001")"
DOZZLE_PORT="$(prompt "Dozzle logs port" "9999")"

copy_or_download_compose "$INSTALL_DIR"
prepare_directories
write_env_file "$INSTALL_DIR/.env"

log "Starting Monitoring Stack"
docker compose --env-file "$INSTALL_DIR/.env" -f "$INSTALL_DIR/$COMPOSE_FILE_NAME" up -d

log "Monitoring Stack complete"
printf 'Uptime Kuma URL: http://SERVER-IP:%s\n' "$UPTIME_KUMA_PORT"
printf 'Dozzle URL: http://SERVER-IP:%s\n' "$DOZZLE_PORT"
