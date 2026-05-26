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
  if ! command -v pveversion >/dev/null 2>&1; then
    die "This script must be run on a Proxmox VE host."
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

disable_enterprise_repos() {
  local files=(
    /etc/apt/sources.list.d/pve-enterprise.list
    /etc/apt/sources.list.d/ceph.list
  )
  local file

  log "Disabling enterprise repositories if present"
  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      cp "$file" "$file.bak"
      sed -i 's/^[[:space:]]*deb /# deb /' "$file"
    fi
  done
}

enable_no_subscription_repo() {
  local codename
  local repo_file="/etc/apt/sources.list.d/pve-no-subscription.list"

  # shellcheck disable=SC1091
  . /etc/os-release
  codename="${VERSION_CODENAME:-bookworm}"

  log "Enabling Proxmox no-subscription repository"
  printf 'deb http://download.proxmox.com/debian/pve %s pve-no-subscription\n' "$codename" > "$repo_file"
}

install_tools() {
  log "Installing useful Proxmox host tools"
  apt-get update
  apt-get install -y curl git htop iftop iotop jq lsof nano net-tools tmux unzip
}

update_system() {
  log "Updating Proxmox packages"
  apt-get update
  apt-get dist-upgrade -y
}

require_root
require_proxmox

log "Proxmox Post Install guided helper"
printf 'Detected: %s\n' "$(pveversion)"

if prompt_yes_no "Disable enterprise repositories that require a subscription?" "Y"; then
  disable_enterprise_repos
fi

if prompt_yes_no "Enable the Proxmox no-subscription repository?" "Y"; then
  enable_no_subscription_repo
fi

if prompt_yes_no "Install useful admin tools?" "Y"; then
  install_tools
fi

if prompt_yes_no "Update Proxmox packages now?" "N"; then
  update_system
fi

log "Proxmox post-install helper complete"
printf 'Review repository files in /etc/apt/sources.list.d before major upgrades.\n'
