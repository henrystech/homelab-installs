#!/usr/bin/env bash

set -Eeuo pipefail

INSTALL_DIR_DEFAULT="/volume1/docker/homelab-compose"
REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/henrystech/homelab-installs/main/nas-compose-bootstrap}"
COMPOSE_FILE_NAME="docker-compose.yaml"

log() {
  printf '\n==> %s\n' "$1"
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
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

find_compose_command() {
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(docker compose)
    return 0
  fi

  if command_exists docker-compose; then
    COMPOSE_CMD=(docker-compose)
    return 0
  fi

  return 1
}

write_env_file() {
  cat > "$INSTALL_DIR/.env" <<ENVEOF
TZ=$(env_value "$TZ")
APPDATA_DIR=$(env_value "$APPDATA_DIR")
DATA_DIR=$(env_value "$DATA_DIR")
UPTIME_KUMA_PORT=$(env_value "$UPTIME_KUMA_PORT")
FILEBROWSER_PORT=$(env_value "$FILEBROWSER_PORT")
PUID=$(env_value "$PUID")
PGID=$(env_value "$PGID")
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

log "NAS Compose Bootstrap"
INSTALL_DIR="$(prompt "Compose project folder" "$INSTALL_DIR_DEFAULT")"
TZ="$(prompt "Timezone" "America/Chicago")"
APPDATA_DIR="$(prompt "Appdata/config folder" "$INSTALL_DIR")"
DATA_DIR="$(prompt "NAS folder exposed in File Browser" "/volume1")"
PUID="$(prompt "PUID" "1000")"
PGID="$(prompt "PGID" "1000")"
UPTIME_KUMA_PORT="$(prompt "Uptime Kuma port" "3001")"
FILEBROWSER_PORT="$(prompt "File Browser port" "8081")"

mkdir -p \
  "$INSTALL_DIR" \
  "$APPDATA_DIR/uptime-kuma/data" \
  "$APPDATA_DIR/filebrowser/database" \
  "$APPDATA_DIR/filebrowser/config"

write_env_file
copy_or_download_compose

log "NAS Compose files created"
printf 'Project folder: %s\n' "$INSTALL_DIR"
printf 'Compose file: %s/%s\n' "$INSTALL_DIR" "$COMPOSE_FILE_NAME"
printf 'Environment file: %s/.env\n' "$INSTALL_DIR"

if find_compose_command && prompt_yes_no "Start the Compose project now?" "N"; then
  "${COMPOSE_CMD[@]}" --env-file "$INSTALL_DIR/.env" -f "$INSTALL_DIR/$COMPOSE_FILE_NAME" up -d
else
  printf '\nImport the project in Synology Container Manager or UGREEN Docker if you prefer using the NAS web UI.\n'
fi
