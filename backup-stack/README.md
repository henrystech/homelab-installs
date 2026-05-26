# Backup Stack Guided Installer

This folder installs a simple Kopia backup web UI using Docker Compose. It is meant to help users back up important homelab folders such as `/docker`, app configuration folders, Compose files, and `.env` files.

## Services

- Kopia
- Custom Docker bridge network named `skynet`

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/backup-stack/backup-stack.sh | sudo bash
```

## What It Does

The installer:

- checks that Docker Compose is available
- asks where the stack should be installed
- asks which folder should be backed up
- asks where the backup repository should live
- creates Kopia config/cache folders
- writes a private `.env` file
- starts the Kopia web UI

## Generated Files

Example default layout:

```text
/docker/backup-stack/docker-compose.yaml
/docker/backup-stack/.env
/docker/backup-stack/kopia/config
/docker/backup-stack/kopia/cache
```

The backup repository is stored wherever you choose, commonly on mounted NAS storage such as `/mnt/backups/kopia`.

## Installer Choices Explained

- `Stack install directory`: where this stack's Compose file and `.env` file live.
- `Timezone`: the timezone passed into the container.
- `Container config directory`: where Kopia stores app configuration and cache.
- `Folder to back up`: the host folder mounted read-only into Kopia as `/source`.
- `Backup repository folder`: the host folder mounted into Kopia as `/repository`.
- `Kopia web UI port`: the port used to open Kopia in a browser.
- `Kopia web UI username`: the username for the Kopia web UI.
- `Kopia web UI password`: the password for the Kopia web UI. This is written only to the local `.env` file.

## Important Backup Lesson

Installing a backup tool is only the first half. A good backup plan also needs a restore test. After creating your first snapshot in Kopia, try restoring a small file to a temporary folder so you know the backup works.
