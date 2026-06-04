#!/usr/bin/env bash

set -Eeuo pipefail

REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/henrystech/homelab-installs/main/media-server-stack}"
INSTALL_DIR_DEFAULT="/opt/homelab/media-server-stack"
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
    die "Please run as root: sudo ./media-server-stack.sh"
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
MEDIA_DIR=$(env_value "$MEDIA_DIR")
JELLYFIN_PORT=$(env_value "$JELLYFIN_PORT")
JELLYSEERR_PORT=$(env_value "$JELLYSEERR_PORT")
ENVEOF

  chmod 600 "$env_file"
}

prepare_directories() {
  log "Preparing media server folders"
  mkdir -p \
    "$DOCKERCONFDIR/jellyfin/config" \
    "$DOCKERCONFDIR/jellyfin/cache" \
    "$DOCKERCONFDIR/jellyseerr/config" \
    "$MEDIA_DIR/movies" \
    "$MEDIA_DIR/tv" \
    "$MEDIA_DIR/anime"

  chown -R "$PUID:$PGID" \
    "$DOCKERCONFDIR/jellyfin" \
    "$DOCKERCONFDIR/jellyseerr" \
    "$MEDIA_DIR" || true
}

require_root

log "Media Server Stack guided installer"
require_docker_compose

INSTALL_DIR="$(prompt "Stack install directory" "$INSTALL_DIR_DEFAULT")"
TZ="$(prompt "Timezone" "$(timedatectl show -p Timezone --value 2>/dev/null || printf 'America/Chicago')")"
PUID="$(prompt "PUID" "1000")"
PGID="$(prompt "PGID" "1000")"
DOCKERCONFDIR="$(prompt "Container config directory" "$INSTALL_DIR")"
MEDIA_DIR="$(prompt "Media directory" "/mnt/data/media")"
JELLYFIN_PORT="$(prompt "Jellyfin port" "8096")"
JELLYSEERR_PORT="$(prompt "Jellyseerr port" "5055")"

copy_or_download_compose "$INSTALL_DIR"
prepare_directories
write_env_file "$INSTALL_DIR/.env"

log "Starting Media Server Stack"
docker compose --env-file "$INSTALL_DIR/.env" -f "$INSTALL_DIR/$COMPOSE_FILE_NAME" up -d

log "Media Server Stack complete"
printf 'Jellyfin URL: http://SERVER-IP:%s\n' "$JELLYFIN_PORT"
printf 'Jellyseerr URL: http://SERVER-IP:%s\n' "$JELLYSEERR_PORT"
printf 'Media folders are under: %s\n' "$MEDIA_DIR"
