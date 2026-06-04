#!/usr/bin/env bash

set -Eeuo pipefail

REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/henrystech/homelab-installs/main/dns-vpn-stack}"
INSTALL_DIR_DEFAULT="/opt/homelab/dns-vpn-stack"
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
    die "Please run as root: sudo ./dns-vpn-stack.sh"
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
ADGUARD_DNS_PORT=$(env_value "$ADGUARD_DNS_PORT")
ADGUARD_SETUP_PORT=$(env_value "$ADGUARD_SETUP_PORT")
ADGUARD_HTTP_PORT=$(env_value "$ADGUARD_HTTP_PORT")
COMPOSE_PROFILES=$(env_value "$COMPOSE_PROFILES")
WG_HOST=$(env_value "$WG_HOST")
WG_PASSWORD_HASH=$(env_value "$WG_PASSWORD_HASH")
WG_WEB_PORT=$(env_value "$WG_WEB_PORT")
WG_UDP_PORT=$(env_value "$WG_UDP_PORT")
WG_DEFAULT_DNS=$(env_value "$WG_DEFAULT_DNS")
ENVEOF

  chmod 600 "$env_file"
}

prepare_directories() {
  log "Preparing DNS/VPN folders"
  mkdir -p \
    "$DOCKERCONFDIR/adguard/work" \
    "$DOCKERCONFDIR/adguard/conf" \
    "$DOCKERCONFDIR/wg-easy"
}

require_root

log "DNS/VPN Stack guided installer"
require_docker_compose

INSTALL_DIR="$(prompt "Stack install directory" "$INSTALL_DIR_DEFAULT")"
TZ="$(prompt "Timezone" "$(timedatectl show -p Timezone --value 2>/dev/null || printf 'America/Chicago')")"
DOCKERCONFDIR="$(prompt "Container config directory" "$INSTALL_DIR")"
ADGUARD_DNS_PORT="$(prompt "AdGuard DNS port" "53")"
ADGUARD_SETUP_PORT="$(prompt "AdGuard first-run setup port" "3002")"
ADGUARD_HTTP_PORT="$(prompt "AdGuard admin HTTP port after setup" "8082")"
COMPOSE_PROFILES=""
WG_HOST=""
WG_PASSWORD_HASH=""
WG_WEB_PORT="51821"
WG_UDP_PORT="51820"
WG_DEFAULT_DNS=""

if prompt_yes_no "Include wg-easy WireGuard VPN container?" "N"; then
  COMPOSE_PROFILES="wireguard"
  WG_HOST="$(prompt_required "WireGuard public host or IP" "")"
  WG_PASSWORD_HASH="$(prompt_secret "wg-easy admin PASSWORD_HASH")"
  WG_WEB_PORT="$(prompt "wg-easy web UI port" "51821")"
  WG_UDP_PORT="$(prompt "WireGuard UDP port" "51820")"
  WG_DEFAULT_DNS="$(prompt "WireGuard client DNS server" "1.1.1.1")"
fi

copy_or_download_compose "$INSTALL_DIR"
prepare_directories
write_env_file "$INSTALL_DIR/.env"

log "Starting DNS/VPN Stack"
if [[ -n "$COMPOSE_PROFILES" ]]; then
  docker compose --profile "$COMPOSE_PROFILES" --env-file "$INSTALL_DIR/.env" -f "$INSTALL_DIR/$COMPOSE_FILE_NAME" up -d
else
  docker compose --env-file "$INSTALL_DIR/.env" -f "$INSTALL_DIR/$COMPOSE_FILE_NAME" up -d
fi

log "DNS/VPN Stack complete"
printf 'AdGuard first-run URL: http://SERVER-IP:%s\n' "$ADGUARD_SETUP_PORT"
printf 'AdGuard DNS port: %s/tcp and %s/udp\n' "$ADGUARD_DNS_PORT" "$ADGUARD_DNS_PORT"
if [[ "$COMPOSE_PROFILES" == "wireguard" ]]; then
  printf 'wg-easy URL: http://SERVER-IP:%s\n' "$WG_WEB_PORT"
  printf 'WireGuard UDP port: %s\n' "$WG_UDP_PORT"
fi
