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
    die "Please run as root: sudo ./storage-mount-helper.sh"
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

install_packages() {
  local mount_type="$1"

  if ! command_exists apt-get; then
    die "Automatic package installation currently supports Ubuntu/Debian hosts with apt-get."
  fi

  log "Installing mount packages"
  apt-get update

  case "$mount_type" in
    NFS) apt-get install -y nfs-common ;;
    SMB) apt-get install -y cifs-utils ;;
    *) die "Unsupported mount type: $mount_type" ;;
  esac
}

backup_fstab() {
  local backup_file

  backup_file="/etc/fstab.homelab-backup.$(date +%Y%m%d%H%M%S)"
  cp /etc/fstab "$backup_file"
  printf 'Backed up /etc/fstab to %s\n' "$backup_file"
}

append_fstab_once() {
  local match="$1"
  local entry="$2"

  backup_fstab

  if grep -qsF "$match" /etc/fstab; then
    printf 'An /etc/fstab entry for this mount already exists.\n'
  else
    printf '%s\n' "$entry" >> /etc/fstab
  fi
}

setup_nfs() {
  local nas_ip
  local nas_export
  local mount_point
  local nfs_version
  local options
  local entry

  nas_ip="$(prompt_required "NAS IP address" "")"
  nas_export="$(prompt_required "NAS NFS export path" "/volume1/data")"
  mount_point="$(prompt_required "Local mount point" "/mnt/data")"
  nfs_version="$(prompt "NFS version" "4")"
  options="$(prompt "NFS mount options" "defaults,_netdev,nofail,vers=$nfs_version")"

  mkdir -p "$mount_point"
  MOUNT_POINT="$mount_point"

  if command_exists showmount; then
    showmount -e "$nas_ip" || true
  fi

  entry="$nas_ip:$nas_export $mount_point nfs $options 0 0"
  append_fstab_once "$nas_ip:$nas_export $mount_point nfs" "$entry"
}

setup_smb() {
  local share_path
  local mount_point
  local credentials_file
  local username
  local password
  local domain
  local uid
  local gid
  local options
  local entry

  share_path="$(prompt_required "SMB share path" "//NAS-IP/share")"
  mount_point="$(prompt_required "Local mount point" "/mnt/data")"
  credentials_file="$(prompt "Credentials file" "/root/.smbcredentials-homelab")"
  username="$(prompt_required "SMB username" "")"
  password="$(prompt_secret "SMB password")"
  domain="$(prompt "SMB domain or workgroup" "")"
  uid="$(prompt "Local owner UID" "1000")"
  gid="$(prompt "Local owner GID" "1000")"
  options="$(prompt "SMB mount options" "credentials=$credentials_file,uid=$uid,gid=$gid,file_mode=0664,dir_mode=0775,_netdev,nofail,iocharset=utf8")"

  mkdir -p "$mount_point"
  MOUNT_POINT="$mount_point"

  {
    printf 'username=%s\n' "$username"
    printf 'password=%s\n' "$password"
    if [[ -n "$domain" ]]; then
      printf 'domain=%s\n' "$domain"
    fi
  } > "$credentials_file"
  chmod 600 "$credentials_file"

  entry="$share_path $mount_point cifs $options 0 0"
  append_fstab_once "$share_path $mount_point cifs" "$entry"
}

test_mount() {
  log "Testing mounts"
  mount -a
  findmnt "$MOUNT_POINT" || true
}

require_root

log "Storage Mount Helper"
MOUNT_TYPE="$(choose_option "Storage type" "NFS" "SMB")"
install_packages "$MOUNT_TYPE"

case "$MOUNT_TYPE" in
  NFS)
    setup_nfs
    ;;
  SMB)
    setup_smb
    ;;
esac

test_mount

log "Storage mount helper complete"
printf 'Mount point: %s\n' "$MOUNT_POINT"
printf 'Use this path in Docker stacks as the host storage path.\n'
