# Reverse Proxy Stack Guided Installer

This folder installs Nginx Proxy Manager and can optionally run a Cloudflare Tunnel container.

Use this when you want friendly names for services instead of remembering ports, such as `sonarr.example.com`, `jellyfin.example.com`, or `uptime.example.com`.

## Services

- Nginx Proxy Manager
- optional Cloudflare Tunnel
- Custom Docker bridge network named `skynet`

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/reverse-proxy-stack/reverse-proxy-stack.sh | sudo bash
```

## What It Does

The installer:

- checks that Docker Compose is available
- asks where to install the stack
- asks which ports to use for HTTP, HTTPS, and the admin UI
- optionally asks for a Cloudflare Tunnel token
- creates persistent config folders
- writes a private `.env` file
- starts the stack

## Generated Files

```text
/opt/homelab/reverse-proxy-stack/docker-compose.yaml
/opt/homelab/reverse-proxy-stack/.env
/opt/homelab/reverse-proxy-stack/nginx-proxy-manager/data
/opt/homelab/reverse-proxy-stack/nginx-proxy-manager/letsencrypt
```

## Installer Choices Explained

- `Stack install directory`: where this stack's Compose file and `.env` file live.
- `Timezone`: the timezone passed into the containers.
- `Container config directory`: where Nginx Proxy Manager and Cloudflare Tunnel store persistent data.
- `HTTP port`: the public HTTP port. This is usually `80`.
- `HTTPS port`: the public HTTPS port. This is usually `443`.
- `Nginx Proxy Manager admin port`: the port used to open the Nginx Proxy Manager web UI.
- `Include Cloudflare Tunnel container?`: starts a tunnel container for users who want Cloudflare-managed access without opening inbound router ports.
- `Cloudflare Tunnel token`: a secret token generated in Cloudflare Zero Trust. This is written only to the local `.env` file.

## Learning Notes

A reverse proxy receives browser traffic on ports `80` and `443`, then forwards that traffic to containers on the Docker network. This lets users expose fewer ports and give services clean names.

If you use Cloudflare Tunnel, the tunnel connects outward to Cloudflare. That can avoid router port forwarding, but you should still understand what services you are publishing.
