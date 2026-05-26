#!/usr/bin/env bash

set -Eeuo pipefail

log() {
  printf '\n==> %s\n' "$1"
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "Please run as root on the Proxmox host."
  fi

  if [[ ! -r /dev/tty ]]; then
    die "This guided installer needs an interactive terminal."
  fi
}

require_proxmox() {
  if ! command -v pct >/dev/null 2>&1; then
    die "This script must be run on a Proxmox VE host with pct available."
  fi
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

create_lxc() {
  if pct status "$CTID" >/dev/null 2>&1; then
    die "Container ID $CTID already exists."
  fi

  log "Creating LXC $CTID"
  pct create "$CTID" "$TEMPLATE" \
    --hostname "$HOSTNAME" \
    --cores "$CORES" \
    --memory "$MEMORY" \
    --rootfs "${STORAGE}:${DISK_SIZE}" \
    --net0 "name=eth0,bridge=${BRIDGE},ip=${IP_CONFIG}" \
    --features nesting=1,keyctl=1 \
    --unprivileged 1 \
    --password "$ROOT_PASSWORD" \
    --start 1
}

install_docker_inside_lxc() {
  log "Installing Docker inside LXC $CTID"
  pct exec "$CTID" -- bash -lc 'apt-get update && apt-get install -y ca-certificates curl gnupg'
  pct exec "$CTID" -- bash -lc '. /etc/os-release && install -m 0755 -d /etc/apt/keyrings && curl -fsSL "https://download.docker.com/linux/${ID}/gpg" -o /etc/apt/keyrings/docker.asc && chmod a+r /etc/apt/keyrings/docker.asc && printf "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/%s %s stable\n" "$ID" "$VERSION_CODENAME" > /etc/apt/sources.list.d/docker.list'
  pct exec "$CTID" -- bash -lc 'apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin'
  pct exec "$CTID" -- bash -lc 'mkdir -p /docker && docker network create skynet >/dev/null 2>&1 || true'
}

require_root
require_proxmox

log "Proxmox Docker LXC guided installer"
printf 'Tip: run "pveam update" and "pveam available --section system" if you need to find templates.\n'

CTID="$(prompt "Container ID" "120")"
HOSTNAME="$(prompt "Container hostname" "docker-lxc")"
TEMPLATE="$(prompt "Template volume" "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst")"
STORAGE="$(prompt "Proxmox storage name" "local-lvm")"
DISK_SIZE="$(prompt "Disk size" "32G")"
CORES="$(prompt "CPU cores" "2")"
MEMORY="$(prompt "Memory MB" "2048")"
BRIDGE="$(prompt "Network bridge" "vmbr0")"
IP_CONFIG="$(prompt "IP config" "dhcp")"
ROOT_PASSWORD="$(prompt_secret "Container root password")"

printf '\nContainer summary:\n'
printf '  CTID: %s\n' "$CTID"
printf '  Hostname: %s\n' "$HOSTNAME"
printf '  Template: %s\n' "$TEMPLATE"
printf '  Storage: %s:%s\n' "$STORAGE" "$DISK_SIZE"
printf '  Network: %s, %s\n' "$BRIDGE" "$IP_CONFIG"

if ! prompt_yes_no "Create this Docker LXC now?" "N"; then
  die "Cancelled."
fi

create_lxc

if prompt_yes_no "Install Docker inside the new LXC?" "Y"; then
  install_docker_inside_lxc
fi

log "Proxmox Docker LXC helper complete"
printf 'Enter container: pct enter %s\n' "$CTID"
printf 'Inside the container, Docker config folder: /docker\n'
