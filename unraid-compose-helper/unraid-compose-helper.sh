#!/usr/bin/env bash

set -Eeuo pipefail

INSTALL_DIR_DEFAULT="/mnt/user/appdata/homelab-compose"
REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/henrystech/homelab-installs/main/unraid-compose-helper}"
COMPOSE_FILE_NAME="docker-compose.yaml"

log() {
  printf '\n==> %s\n' "$1"
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
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

env_value() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\'/\\\'}"
  printf "'%s'" "$value"
}

require_interactive() {
  if [[ ! -r /dev/tty ]]; then
    die "This guided helper needs an interactive terminal."
  fi
}

write_env_file() {
  cat > "$INSTALL_DIR/.env" <<ENVEOF
TZ=$(env_value "$TZ")
APPDATA_DIR=$(env_value "$APPDATA_DIR")
DATA_DIR=$(env_value "$DATA_DIR")
UPTIME_KUMA_PORT=$(env_value "$UPTIME_KUMA_PORT")
FILEBROWSER_PORT=$(env_value "$FILEBROWSER_PORT")
ENVEOF
}

copy_or_download_compose() {
  local script_dir

  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P || pwd)"

  if [[ -f "$script_dir/$COMPOSE_FILE_NAME" ]]; then
    install -m 0644 "$script_dir/$COMPOSE_FILE_NAME" "$INSTALL_DIR/$COMPOSE_FILE_NAME"
  else
    curl -fsSL "$REPO_RAW_URL/$COMPOSE_FILE_NAME" -o "$INSTALL_DIR/$COMPOSE_FILE_NAME"
  fi
}

require_interactive

log "Unraid Compose Helper"
INSTALL_DIR="$(prompt "Compose project folder" "$INSTALL_DIR_DEFAULT")"
TZ="$(prompt "Timezone" "America/Chicago")"
APPDATA_DIR="$(prompt "Appdata folder" "/mnt/user/appdata/homelab-compose")"
DATA_DIR="$(prompt "Data folder exposed in File Browser" "/mnt/user")"
UPTIME_KUMA_PORT="$(prompt "Uptime Kuma port" "3001")"
FILEBROWSER_PORT="$(prompt "File Browser port" "8081")"

mkdir -p \
  "$INSTALL_DIR" \
  "$APPDATA_DIR/uptime-kuma/data" \
  "$APPDATA_DIR/filebrowser/database" \
  "$APPDATA_DIR/filebrowser/config"

write_env_file
copy_or_download_compose

log "Unraid Compose files created"
printf 'Project folder: %s\n' "$INSTALL_DIR"
printf 'Compose file: %s/%s\n' "$INSTALL_DIR" "$COMPOSE_FILE_NAME"
printf 'Environment file: %s/.env\n' "$INSTALL_DIR"
printf '\nUse the Unraid Compose Manager plugin to import this project, or run docker compose from the project folder if available.\n'
