# sleepycrab

Docker Compose stack for the sleepycrab homeserver media box
(Proxmox CT 900 "plex", 10.0.0.11). This repo is the stack *definition* —
application state is deliberately not versioned (see "What's not in here").

## Services

| Service | Image | Notes |
|---|---|---|
| gluetun | qmcgaw/gluetun | Proton VPN (WireGuard) gateway. Owns the network namespace and all published ports for the download stack. |
| transmission | linuxserver/transmission | Shares gluetun's namespace. 91-torrent state lives in `$DATA_ROOT/downloads/transmission-home`. |
| prowlarr | linuxserver/prowlarr | Shares gluetun's namespace. |
| flaresolverr | flaresolverr/flaresolverr | Shares gluetun's namespace. |
| plex | plexinc/pms-docker | Host networking; needs `/dev/dri` (iGPU) on the Docker host. |
| sonarr / radarr | linuxserver/* | Reach transmission at `http://transmission-openvpn:9091` (network alias on gluetun). |
| seerr | seerr-team/seerr | Exposed via traefik at media.nymori.com. |
| traefik | traefik:v3 | Reverse proxy; expects the compose network to be named `sleepycrab_default` (pinned in the compose file). |
| tunnel | cloudflare/cloudflared | Cloudflare Tunnel; token from `.env`. |
| ntfy | binwiederhier/ntfy | Alert server (host port 8081). |
| watchtower | containrrr/watchtower | Auto-updates images (with cleanup). Images are intentionally unpinned — watchtower is the update mechanism. |

## Port forwarding (Proton NAT-PMP)

Proton assigns a **new** forwarded port on essentially every tunnel restart,
so transmission's peer port must follow gluetun automatically:

- The WireGuard key in `.env` must be generated with **NAT-PMP (Port
  Forwarding) = on**, or Proton refuses forwarding.
- gluetun's `VPN_PORT_FORWARDING_UP_COMMAND` runs `scripts/pf-sync.sh`
  (bind-mounted into gluetun) with the forwarded port; the script sets
  transmission's peer port over RPC at `127.0.0.1:9091` (shared namespace).

## Secrets

No secrets are committed. The compose file reads two values from `.env`
(copy `.env.example`):

- `WIREGUARD_PRIVATE_KEY` — Proton WireGuard key (full generated config is
  kept on the host at `/root/secrets/wg0.conf`).
- `TUNNEL_TOKEN` — Cloudflare Tunnel token.

## Host requirements

- Docker host with `/dev/net/tun` and `/dev/dri` available to containers.
- `$DATA_ROOT` (default `/data`) — the storage pool (mergerfs) with
  `media/`, `downloads/`, etc.
- `./configs/` — per-app state directories (created by the apps on first
  run). On the production box these hold years of state; a fresh deploy
  starts empty.
- Legacy `docker-compose` 1.27 or Compose v2; file format 3.8.

## Deploy

```sh
cp .env.example .env   # fill in the two secrets
docker-compose up -d
```

## What's not in here

- `configs/` — app databases, API keys, Plex metadata/cache (~50k files).
  Backed up with the host, not git.
- `letsencrypt/` — traefik certificate storage.
- `.env` and `/root/secrets/` — credentials.
