#!/usr/bin/env bash

set -Eeuo pipefail

REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/henrystech/homelab-installs/main/dashboard-stack}"
INSTALL_DIR_DEFAULT="/opt/homelab/dashboard-stack"
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
    die "Please run as root: sudo ./dashboard-stack.sh"
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
PUID=$(env_value "$PUID")
PGID=$(env_value "$PGID")
TZ=$(env_value "$TZ")
DOCKERCONFDIR=$(env_value "$DOCKERCONFDIR")
HOMEPAGE_PORT=$(env_value "$HOMEPAGE_PORT")
HOMEPAGE_ALLOWED_HOSTS=$(env_value "$HOMEPAGE_ALLOWED_HOSTS")
ENVEOF

  chmod 600 "$env_file"
}

write_homepage_config() {
  local config_dir="$DOCKERCONFDIR/homepage/config"

  mkdir -p "$config_dir"

  if [[ ! -f "$config_dir/settings.yaml" ]]; then
    cat > "$config_dir/settings.yaml" <<'YAMLEOF'
title: Homelab
theme: dark
color: slate
headerStyle: boxed
YAMLEOF
  fi

  if [[ ! -f "$config_dir/services.yaml" ]]; then
    cat > "$config_dir/services.yaml" <<'YAMLEOF'
- Media:
    - Jellyfin:
        href: http://SERVER-IP:8096
        description: Media server
    - Sonarr Anime:
        href: http://SERVER-IP:8989
        description: Anime show automation
    - Radarr:
        href: http://SERVER-IP:7878
        description: Movie automation

- Infrastructure:
    - Uptime Kuma:
        href: http://SERVER-IP:3001
        description: Uptime checks
    - Dozzle:
        href: http://SERVER-IP:9999
        description: Container logs
    - Nginx Proxy Manager:
        href: http://SERVER-IP:81
        description: Reverse proxy
YAMLEOF
  fi

  if [[ ! -f "$config_dir/bookmarks.yaml" ]]; then
    cat > "$config_dir/bookmarks.yaml" <<'YAMLEOF'
- Homelab:
    - GitHub Repo:
        - href: https://github.com/henrystech/homelab-installs
YAMLEOF
  fi

  if [[ ! -f "$config_dir/widgets.yaml" ]]; then
    cat > "$config_dir/widgets.yaml" <<'YAMLEOF'
- resources:
    cpu: true
    memory: true
    disk: /
YAMLEOF
  fi
}

prepare_directories() {
  log "Preparing dashboard folders"
  mkdir -p "$DOCKERCONFDIR/homepage/config"
  write_homepage_config
  chown -R "$PUID:$PGID" "$DOCKERCONFDIR/homepage" || true
}

require_root

log "Dashboard Stack guided installer"
require_docker_compose

INSTALL_DIR="$(prompt "Stack install directory" "$INSTALL_DIR_DEFAULT")"
TZ="$(prompt "Timezone" "$(timedatectl show -p Timezone --value 2>/dev/null || printf 'America/Chicago')")"
PUID="$(prompt "PUID" "1000")"
PGID="$(prompt "PGID" "1000")"
DOCKERCONFDIR="$(prompt "Container config directory" "$INSTALL_DIR")"
HOMEPAGE_PORT="$(prompt "Homepage port" "3000")"
HOMEPAGE_ALLOWED_HOSTS="$(prompt "Allowed dashboard hosts" "localhost,127.0.0.1,SERVER-IP")"

copy_or_download_compose "$INSTALL_DIR"
prepare_directories
write_env_file "$INSTALL_DIR/.env"

log "Starting Dashboard Stack"
docker compose --env-file "$INSTALL_DIR/.env" -f "$INSTALL_DIR/$COMPOSE_FILE_NAME" up -d

log "Dashboard Stack complete"
printf 'Homepage URL: http://SERVER-IP:%s\n' "$HOMEPAGE_PORT"
printf 'Edit dashboard files in: %s/homepage/config\n' "$DOCKERCONFDIR"
