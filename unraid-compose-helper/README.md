# Unraid Compose Helper

This folder creates an Unraid-friendly Docker Compose project. It does not replace Unraid Community Applications; it gives users a clean Compose file they can import, study, and modify.

## Services

- Uptime Kuma
- File Browser
- Custom Docker bridge network named `skynet`

## Quick Install

Run this from an Unraid terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/unraid-compose-helper/unraid-compose-helper.sh | bash
```

## What It Does

The helper:

- asks where to create the Compose project
- asks where app data should live
- asks which Unraid share/folder File Browser should expose
- writes a `.env` file
- writes a `docker-compose.yaml`
- creates the appdata folders

## Generated Files

Default layout:

```text
/mnt/user/appdata/homelab-compose/docker-compose.yaml
/mnt/user/appdata/homelab-compose/.env
/mnt/user/appdata/homelab-compose/uptime-kuma/data
/mnt/user/appdata/homelab-compose/filebrowser/database
/mnt/user/appdata/homelab-compose/filebrowser/config
```

## Installer Choices Explained

- `Compose project folder`: where the Compose project files are created.
- `Timezone`: the timezone passed into containers.
- `Appdata folder`: where persistent app configuration is stored.
- `Data folder exposed in File Browser`: the Unraid path shown inside File Browser.
- `Uptime Kuma port`: the browser port for Uptime Kuma.
- `File Browser port`: the browser port for File Browser.

## Notes

- Unraid users often install apps through Community Applications. This helper is for users who want the Compose-file approach.
- File Browser uses Unraid's common `nobody:users` IDs, `99:100`.
- The script creates files but does not force-start containers, because many Unraid users prefer importing Compose projects through the Unraid web UI.
