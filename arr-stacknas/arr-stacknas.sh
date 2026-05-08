#!/usr/bin/env bash

set -Eeuo pipefail

REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/henrystech/homelab-installs/main/arr-stacknas}"
INSTALL_DIR_DEFAULT="/volume1/docker/arr-stack"
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
    die "Please run as root: sudo ./arr-stacknas.sh"
  fi

  if [[ ! -r /dev/tty ]]; then
    die "This guided installer needs an interactive terminal."
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
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

choose_option() {
  local label="$1"
  shift
  local options=("$@")
  local selection

  printf '\n%s\n' "$label" >/dev/tty
  local i
  for i in "${!options[@]}"; do
    printf '  %s) %s\n' "$((i + 1))" "${options[$i]}" >/dev/tty
  done

  while true; do
    printf 'Choose 1-%s: ' "${#options[@]}" >/dev/tty
    read -r selection </dev/tty
    if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#options[@]} )); then
      printf '%s' "${options[$((selection - 1))]}"
      return
    fi
    printf 'Please choose a valid option.\n' >/dev/tty
  done
}

find_compose_command() {
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(docker compose)
    return
  fi

  if command_exists docker-compose; then
    COMPOSE_CMD=(docker-compose)
    return
  fi

  die "Docker Compose was not found. Install Synology Container Manager, UGREEN Docker, or docker-compose first."
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

  cat > "$env_file" <<EOF
PUID=$(env_value "$PUID")
PGID=$(env_value "$PGID")
TZ=$(env_value "$TZ")
DOCKERCONFDIR=$(env_value "$DOCKERCONFDIR")
DOCKERSTORAGEDIR=$(env_value "$DOCKERSTORAGEDIR")
DOCKERLOGGING_MAXFILE=$(env_value "$DOCKERLOGGING_MAXFILE")
DOCKERLOGGING_MAXSIZE=$(env_value "$DOCKERLOGGING_MAXSIZE")

QBITTORRENT_PORT=$(env_value "$QBITTORRENT_PORT")
SABNZBD_PORT=$(env_value "$SABNZBD_PORT")
PROWLARR_PORT=$(env_value "$PROWLARR_PORT")
RADARR_PORT=$(env_value "$RADARR_PORT")
SONARR_ANIME_PORT=$(env_value "$SONARR_ANIME_PORT")
LIDARR_PORT=$(env_value "$LIDARR_PORT")
FILEBROWSER_PORT=$(env_value "$FILEBROWSER_PORT")

VPN_SERVICE_PROVIDER=$(env_value "$VPN_SERVICE_PROVIDER")
VPN_TYPE=$(env_value "$VPN_TYPE")
OPENVPN_USER=$(env_value "$OPENVPN_USER")
OPENVPN_PASSWORD=$(env_value "$OPENVPN_PASSWORD")
SERVER_CITIES=$(env_value "$SERVER_CITIES")

FILEBROWSER_ROOT=$(env_value "$FILEBROWSER_ROOT")
EOF

  chmod 600 "$env_file"
}

prepare_directories() {
  log "Preparing stack directories"

  mkdir -p \
    "$DOCKERCONFDIR/gluetun/config" \
    "$DOCKERCONFDIR/qbittorrent/config" \
    "$DOCKERCONFDIR/sabnzbd/config" \
    "$DOCKERCONFDIR/filebrowser/database" \
    "$DOCKERCONFDIR/filebrowser/config" \
    "$DOCKERCONFDIR/prowlarr/config" \
    "$DOCKERCONFDIR/radarr/config" \
    "$DOCKERCONFDIR/sonarr-anime/config" \
    "$DOCKERCONFDIR/lidarr/config" \
    "$DOCKERSTORAGEDIR/torrents" \
    "$DOCKERSTORAGEDIR/usenet"

  chown -R "$PUID:$PGID" \
    "$DOCKERCONFDIR/gluetun" \
    "$DOCKERCONFDIR/qbittorrent" \
    "$DOCKERCONFDIR/sabnzbd" \
    "$DOCKERCONFDIR/filebrowser" \
    "$DOCKERCONFDIR/prowlarr" \
    "$DOCKERCONFDIR/radarr" \
    "$DOCKERCONFDIR/sonarr-anime" \
    "$DOCKERCONFDIR/lidarr" \
    "$DOCKERSTORAGEDIR/torrents" \
    "$DOCKERSTORAGEDIR/usenet" || true
}

require_root

if ! command_exists docker; then
  die "Docker was not found. Install Container Manager/Docker on the NAS first."
fi
find_compose_command

log "NAS Arr Stack guided installer"

NAS_TYPE="$(choose_option "What NAS is this running on?" "Synology NAS" "UGREEN NAS" "Other NAS Docker host")"
case "$NAS_TYPE" in
  "Synology NAS")
    DEFAULT_INSTALL_DIR="/volume1/docker/arr-stack"
    DEFAULT_STORAGE_DIR="/volume1/data"
    ;;
  "UGREEN NAS")
    DEFAULT_INSTALL_DIR="/volume1/docker/arr-stack"
    DEFAULT_STORAGE_DIR="/volume1/data"
    ;;
  *)
    DEFAULT_INSTALL_DIR="$INSTALL_DIR_DEFAULT"
    DEFAULT_STORAGE_DIR="/volume1/data"
    ;;
esac

INSTALL_DIR="$(prompt_required "Docker install/config directory" "$DEFAULT_INSTALL_DIR")"
DOCKERCONFDIR="$(prompt_required "Container config directory" "$INSTALL_DIR")"
DOCKERSTORAGEDIR="$(prompt_required "NAS media storage directory" "$DEFAULT_STORAGE_DIR")"

PUID="$(prompt_required "PUID" "1000")"
PGID="$(prompt_required "PGID" "1000")"
TZ="$(prompt_required "Timezone" "America/Chicago")"

DOCKERLOGGING_MAXFILE="$(prompt_required "Docker log max files" "10")"
DOCKERLOGGING_MAXSIZE="$(prompt_required "Docker log max size" "200k")"

QBITTORRENT_PORT="$(prompt_required "qBittorrent Web UI port" "8090")"
SABNZBD_PORT="$(prompt_required "SABnzbd Web UI port" "8080")"
PROWLARR_PORT="$(prompt_required "Prowlarr port" "9696")"
RADARR_PORT="$(prompt_required "Radarr port" "7878")"
SONARR_ANIME_PORT="$(prompt_required "Sonarr anime port" "8989")"
LIDARR_PORT="$(prompt_required "Lidarr port" "8686")"
FILEBROWSER_PORT="$(prompt_required "File Browser port" "9898")"

VPN_SERVICE_PROVIDER="$(prompt_required "VPN service provider for Gluetun" "private internet access")"
VPN_TYPE="$(prompt_required "VPN type" "openvpn")"
OPENVPN_USER="$(prompt_required "OpenVPN username")"
OPENVPN_PASSWORD="$(prompt_secret "OpenVPN password")"
SERVER_CITIES="$(prompt_required "VPN server cities/regions" "Netherlands")"

FILEBROWSER_ROOT="$(prompt_required "File Browser root directory" "$DOCKERSTORAGEDIR")"

copy_or_download_compose "$INSTALL_DIR"
write_env_file "$INSTALL_DIR/.env"
prepare_directories

log "Starting containers"
cd "$INSTALL_DIR"
"${COMPOSE_CMD[@]}" up -d

log "Setup complete"
printf 'Compose directory: %s\n' "$INSTALL_DIR"
printf 'Storage directory: %s\n' "$DOCKERSTORAGEDIR"
printf 'Docker network: skynet\n'
printf 'qBittorrent: http://<nas-ip>:%s\n' "$QBITTORRENT_PORT"
printf 'SABnzbd: http://<nas-ip>:%s\n' "$SABNZBD_PORT"
printf 'Prowlarr: http://<nas-ip>:%s\n' "$PROWLARR_PORT"
printf 'Radarr: http://<nas-ip>:%s\n' "$RADARR_PORT"
printf 'Sonarr anime: http://<nas-ip>:%s\n' "$SONARR_ANIME_PORT"
printf 'Lidarr: http://<nas-ip>:%s\n' "$LIDARR_PORT"
printf 'File Browser: http://<nas-ip>:%s\n' "$FILEBROWSER_PORT"
