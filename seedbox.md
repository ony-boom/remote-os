# Seedbox

Download on hizuru's uplink, fetch over HTTPS later. Configured in
[`config/host/hizuru/users/ony/seedbox/`](config/host/hizuru/users/ony/seedbox/).

Not a debrid: nothing here delivers an already-cached torrent instantly, and
nothing unrestricts premium hoster links. What it does is download unattended at
datacenter speed from slow seeds and flaky links, then hand you a fast, resumable
HTTPS link.

## What is exposed

Only the files are public. Everything with a control surface is tailnet-only,
published with `tailscale serve` — see [tailscale.md](tailscale.md).

| Reached at                                | Component    | Auth                |
| ----------------------------------------- | ------------ | ------------------- |
| `https://dl.ony.world`                    | caddy files  | basic, public       |
| `https://hizuru.tempel-goblin.ts.net:8090` | qBittorrent  | tailnet             |
| `https://hizuru.tempel-goblin.ts.net:7081` | aria2/AriaNg | tailnet + RPC token |
| `https://hizuru.tempel-goblin.ts.net:5800` | JDownloader  | tailnet + its login |

The public firewall gains exactly one port, `51413` for BitTorrent. qBittorrent,
aria2 and JDownloader all stay bound to `127.0.0.1`; tailscaled is what reaches
them, which is also why no `firewall.interfaces.tailscale0` rule is needed.

qBittorrent is deliberately not on a public vhost: its web UI can run an external
program when a torrent finishes, so whoever gets past the front door gets command
execution as the `qbittorrent` user. The tailnet is device-level WireGuard keys
rather than one password, and mobile clients need no token-path hack for it.

qBittorrent seeds, which publishes hizuru's IP to swarms and makes the VPS
provider's abuse contact the address of record for any notice. aria2 and
JDownloader only pull. Nothing here masks that; there is no VPN on this host.

## Storage

Everything downloads onto a **sparse** 50G ext4 image at `/var/lib/seedbox.img`,
mounted at `/srv/seedbox`. The root LV claims `100%FREE` and ext4 cannot shrink
online, so an image file is the only way to cap this on a box we only reach over
SSH.

The image is created with `truncate`, not `fallocate`: 50G is a **ceiling, not a
reservation**, and the file only costs what is actually stored. hizuru has ~87G
free of 196G and other services share it, so reserving up front would eat most of
the headroom. The mount carries `discard`, so deleting a download returns the
blocks to the host rather than letting the image only ever grow.

The trade for going sparse: if the host fills up from elsewhere, writes inside the
image fail as I/O errors rather than a clean ENOSPC. `df -h /` is the thing to
watch, not `df -h /srv/seedbox`.

`dl.ony.world` serves that tree directly, so nothing is ever copied twice.

## Bootstrap

DNS and the shared caddy env file are not declarative. Do both *before* the first
deploy — caddy does HTTP-01/TLS-ALPN with no DNS challenge configured, so cert
issuance fails on a missing record.

```sh
# 1. One A record -> 94.250.201.16, by hand at the registrar:
#      dl.ony.world
```

```sh
# 2. The basic-auth pair for dl.ony.world, appended to the shared caddy env file.
nix run nixpkgs#caddy -- hash-password        # -> SEEDBOX_BASIC_HASH

cd config/host/hizuru/users/ony/secrets
agenix -e caddy.age
#   SEEDBOX_BASIC_USER=...
#   SEEDBOX_BASIC_HASH=...
```

`aria2.age` (raw token, no `KEY=`) and `jdownloader.age`
(`WEB_AUTHENTICATION_USERNAME` / `WEB_AUTHENTICATION_PASSWORD`) already exist with
generated values. Read them back with `agenix -d <file>.age`, or replace them with
`agenix -e <file>.age`.

```sh
# 3. Deploy. The tailscale serve mappings apply themselves; nothing manual.
cd config && make
```

## AriaNg

AriaNg keeps its RPC settings in browser localStorage, so this is once per
browser. Out of the box it points at `rpcHost: ""` / port 6800, which means *your*
machine, not hizuru — until it is configured it shows a "cannot connect" popup.

Settings -> RPC, or the quick-setup URL below:

| Field    | Value                        |
| -------- | ---------------------------- |
| Protocol | HTTPS                        |
| Host     | `hizuru.tempel-goblin.ts.net` |
| Port     | `7081`                       |
| Path     | `jsonrpc`                    |
| Secret   | the raw token, unencoded     |

```sh
agenix -d aria2.age                # raw token, for the settings form
```

The URL form wants the secret **base64url** encoded, not plain base64: AriaNg runs
it through `base64UrlDecode`, and standard base64 can emit `+`, `/` and `=` - a `/`
breaks the URL path, and the rest trips "RPC secret is not base64 encoded!".

```sh
agenix -d aria2.age | tr -d '\n' | base64 -w0 | tr '+/' '-_' | tr -d '='
```

```
https://hizuru.tempel-goblin.ts.net:7081/#!/settings/rpc/set/https/hizuru.tempel-goblin.ts.net/7081/jsonrpc/<token>
```

## Mobile torrent clients

Point qBitControl or Transdroid at `https://hizuru.tempel-goblin.ts.net:8090` with
Tailscale running on the phone. No credentials: qBittorrent's `LocalHostAuth` is
off and tailscaled reaches it from loopback, so the tailnet is the authentication.
