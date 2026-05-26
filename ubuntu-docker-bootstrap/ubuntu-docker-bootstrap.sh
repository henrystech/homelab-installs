#!/usr/bin/env bash

set -Eeuo pipefail

DOCKER_ROOT_DEFAULT="/docker"
DOCKER_NETWORK_DEFAULT="skynet"

log() {
  printf '\n==> %s\n' "$1"
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "Please run as root: sudo ./ubuntu-docker-bootstrap.sh"
  fi

  if [[ ! -r /dev/tty ]]; then
    die "This guided installer needs an interactive terminal."
  fi
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

install_docker_from_official_repo() {
  local os_id
  local codename
  local repo_file="/etc/apt/sources.list.d/docker.list"

  if command_exists docker && docker compose version >/dev/null 2>&1; then
    log "Docker and Docker Compose are already installed"
    return
  fi

  if ! command_exists apt-get; then
    die "This bootstrap script supports Ubuntu/Debian hosts with apt-get."
  fi

  # shellcheck disable=SC1091
  . /etc/os-release
  os_id="${ID}"
  codename="${VERSION_CODENAME:-}"

  case "$os_id" in
    ubuntu|debian) ;;
    *) die "Unsupported OS '$os_id'. This script supports Ubuntu and Debian." ;;
  esac

  if [[ -z "$codename" ]]; then
    die "Could not detect the OS codename from /etc/os-release."
  fi

  log "Installing Docker from the official Docker apt repository"
  apt-get update
  apt-get install -y ca-certificates curl gnupg

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/${os_id}/gpg" -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/%s %s stable\n' \
    "$(dpkg --print-architecture)" "$os_id" "$codename" > "$repo_file"

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

prepare_folders() {
  local docker_root="$1"

  log "Preparing Docker folder layout"
  mkdir -p "$docker_root"

  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$docker_root" || true
    usermod -aG docker "$SUDO_USER" || true
  fi
}

create_network() {
  local network_name="$1"

  if docker network inspect "$network_name" >/dev/null 2>&1; then
    log "Docker network '$network_name' already exists"
  else
    log "Creating Docker network '$network_name'"
    docker network create "$network_name"
  fi
}

install_optional_basics() {
  log "Installing useful server packages"
  apt-get update
  apt-get install -y curl ca-certificates git nano htop lsof unzip jq
}

configure_unattended_upgrades() {
  log "Installing unattended security updates"
  apt-get update
  apt-get install -y unattended-upgrades
  dpkg-reconfigure -f noninteractive unattended-upgrades || true
}

configure_fail2ban() {
  log "Installing Fail2ban"
  apt-get update
  apt-get install -y fail2ban
  systemctl enable --now fail2ban || true
}

write_summary() {
  local docker_root="$1"
  local network_name="$2"
  local summary_file="$docker_root/bootstrap-summary.txt"

  {
    printf 'Ubuntu Docker Bootstrap Summary\n'
    printf 'Docker root: %s\n' "$docker_root"
    printf 'Docker network: %s\n' "$network_name"
    printf 'Compose command: docker compose\n'
    printf 'Created by: homelab-installs ubuntu-docker-bootstrap\n'
  } > "$summary_file"

  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    chown "$SUDO_USER:$SUDO_USER" "$summary_file" || true
  fi
}

require_root

log "Ubuntu Docker Bootstrap guided installer"

DOCKER_ROOT="$(prompt "Docker root folder" "$DOCKER_ROOT_DEFAULT")"
DOCKER_NETWORK="$(prompt "Default Docker network name" "$DOCKER_NETWORK_DEFAULT")"

install_optional_basics
install_docker_from_official_repo
prepare_folders "$DOCKER_ROOT"
create_network "$DOCKER_NETWORK"

if prompt_yes_no "Install unattended security updates?" "Y"; then
  configure_unattended_upgrades
fi

if prompt_yes_no "Install Fail2ban for basic SSH protection?" "Y"; then
  configure_fail2ban
fi

write_summary "$DOCKER_ROOT" "$DOCKER_NETWORK"

log "Bootstrap complete"
printf 'Docker root: %s\n' "$DOCKER_ROOT"
printf 'Docker network: %s\n' "$DOCKER_NETWORK"
printf 'If your user was added to the docker group, log out and back in before running Docker without sudo.\n'
