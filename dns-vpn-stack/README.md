# DNS/VPN Stack Guided Installer

This folder installs AdGuard Home and can optionally install wg-easy for WireGuard VPN access.

Use this when users want local DNS filtering and a simple private VPN path back into the homelab.

## Services

- AdGuard Home
- optional wg-easy
- Custom Docker bridge network named `skynet`

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/henrystech/homelab-installs/main/dns-vpn-stack/dns-vpn-stack.sh | sudo bash
```

## What It Does

The installer:

- checks that Docker Compose is available
- asks where to install the stack
- asks which DNS and web ports to use
- optionally asks for wg-easy settings
- creates persistent config folders
- writes a private `.env` file
- starts the stack

## Generated Files

```text
/opt/homelab/dns-vpn-stack/docker-compose.yaml
/opt/homelab/dns-vpn-stack/.env
/opt/homelab/dns-vpn-stack/adguard/work
/opt/homelab/dns-vpn-stack/adguard/conf
/opt/homelab/dns-vpn-stack/wg-easy
```

## Installer Choices Explained

- `Stack install directory`: where this stack's Compose file and `.env` file live.
- `Timezone`: the timezone passed into containers.
- `Container config directory`: where AdGuard Home and wg-easy store persistent data.
- `AdGuard DNS port`: the DNS port clients use. This is normally `53`.
- `AdGuard first-run setup port`: the temporary first-run setup UI port.
- `AdGuard admin HTTP port after setup`: the normal admin UI port after AdGuard setup.
- `Include wg-easy WireGuard VPN container?`: adds a VPN web UI and WireGuard server.
- `WireGuard public host or IP`: the public DNS name or IP clients use to reach your VPN.
- `wg-easy admin PASSWORD_HASH`: the bcrypt hash used to log in to wg-easy.
- `WireGuard client DNS server`: DNS server pushed to VPN clients.

## Learning Notes

DNS is how devices turn names into IP addresses. AdGuard Home can become the local DNS server for a network, which also lets it block ads and trackers.

A VPN is a private path back home. WireGuard lets users reach homelab services without exposing every service to the public internet.

Port `53` can conflict with other DNS services on the host. If Docker cannot bind port `53`, check whether another DNS resolver is already listening.
