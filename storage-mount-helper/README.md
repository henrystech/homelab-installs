# Storage Mount Helper

This folder contains a guided helper for mounting NAS storage on Ubuntu/Debian hosts.

Use this when media, backups, or app data live on a NAS but containers run on another Linux server or Proxmox LXC.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/storage-mount-helper/storage-mount-helper.sh | sudo bash
```

## What It Does

The helper:

- asks whether the storage is NFS or SMB
- installs `nfs-common` or `cifs-utils`
- creates the local mount point
- backs up `/etc/fstab`
- adds a persistent mount entry
- runs `mount -a`
- shows the resulting mount

## Installer Choices Explained

- `Storage type`: choose `NFS` for Linux/NAS exports or `SMB` for Windows-style shares.
- `NAS IP address`: the IP address of the NAS that exports the NFS share.
- `NAS NFS export path`: the NFS path shared by the NAS, such as `/volume1/data`.
- `SMB share path`: the SMB path, such as `//192.168.1.10/media`.
- `Local mount point`: where Linux should mount the share, usually `/mnt/data`.
- `NFS version`: the NFS protocol version. Version `4` is a good default.
- `Credentials file`: where SMB credentials are stored. The script locks this file down with `chmod 600`.
- `Local owner UID` and `Local owner GID`: the Linux user and group IDs used for SMB file ownership.
- `Mount options`: the final options written to `/etc/fstab`.

## Learning Notes

Containers should usually mount storage from a stable host path. For example, if this helper mounts a NAS share at `/mnt/data`, Docker Compose files can use `/mnt/data` as the host path.

NFS is often cleaner for Linux-to-NAS storage. SMB is common when the NAS share is also used by Windows or mixed-device clients.
