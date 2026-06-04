#!/usr/bin/env bash

set -Eeuo pipefail

REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/henrystech/homelab-installs/main/reverse-proxy-stack}"
INSTALL_DIR_DEFAULT="/opt/homelab/reverse-proxy-stack"
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
    die "Please run as root: sudo ./reverse-proxy-stack.sh"
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

prompt_required() {
  local label="$1"
  local default_value="${2:-}"
  local answer

  while true; do
    answer="$(prompt "$label" "$default_value")"
    if [[ -n "$answer" ]]; then
      printf '%s' "$answer"
      return
    fi
    printf 'This value is required.\n' >/dev/tty
  done
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
HTTP_PORT=$(env_value "$HTTP_PORT")
HTTPS_PORT=$(env_value "$HTTPS_PORT")
NPM_ADMIN_PORT=$(env_value "$NPM_ADMIN_PORT")
COMPOSE_PROFILES=$(env_value "$COMPOSE_PROFILES")
CLOUDFLARE_TUNNEL_TOKEN=$(env_value "$CLOUDFLARE_TUNNEL_TOKEN")
ENVEOF

  chmod 600 "$env_file"
}

prepare_directories() {
  log "Preparing reverse proxy folders"
  mkdir -p \
    "$DOCKERCONFDIR/nginx-proxy-manager/data" \
    "$DOCKERCONFDIR/nginx-proxy-manager/letsencrypt" \
    "$DOCKERCONFDIR/cloudflared"
}

require_root

log "Reverse Proxy Stack guided installer"
require_docker_compose

INSTALL_DIR="$(prompt "Stack install directory" "$INSTALL_DIR_DEFAULT")"
TZ="$(prompt "Timezone" "$(timedatectl show -p Timezone --value 2>/dev/null || printf 'America/Chicago')")"
DOCKERCONFDIR="$(prompt "Container config directory" "$INSTALL_DIR")"
HTTP_PORT="$(prompt "HTTP port" "80")"
HTTPS_PORT="$(prompt "HTTPS port" "443")"
NPM_ADMIN_PORT="$(prompt "Nginx Proxy Manager admin port" "81")"
COMPOSE_PROFILES=""
CLOUDFLARE_TUNNEL_TOKEN=""

if prompt_yes_no "Include Cloudflare Tunnel container?" "N"; then
  COMPOSE_PROFILES="cloudflare"
  CLOUDFLARE_TUNNEL_TOKEN="$(prompt_secret "Cloudflare Tunnel token")"
fi

copy_or_download_compose "$INSTALL_DIR"
prepare_directories
write_env_file "$INSTALL_DIR/.env"

log "Starting Reverse Proxy Stack"
if [[ -n "$COMPOSE_PROFILES" ]]; then
  docker compose --profile "$COMPOSE_PROFILES" --env-file "$INSTALL_DIR/.env" -f "$INSTALL_DIR/$COMPOSE_FILE_NAME" up -d
else
  docker compose --env-file "$INSTALL_DIR/.env" -f "$INSTALL_DIR/$COMPOSE_FILE_NAME" up -d
fi

log "Reverse Proxy Stack complete"
printf 'Nginx Proxy Manager admin URL: http://SERVER-IP:%s\n' "$NPM_ADMIN_PORT"
printf 'HTTP proxy port: %s\n' "$HTTP_PORT"
printf 'HTTPS proxy port: %s\n' "$HTTPS_PORT"
