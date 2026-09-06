# Seedbox

Download on hizuru's uplink, fetch over HTTPS later. Configured in
[`config/host/hizuru/users/ony/seedbox/`](config/host/hizuru/users/ony/seedbox/).

Not a debrid: nothing here delivers an already-cached torrent instantly, and
nothing unrestricts premium hoster links. What it does is download unattended at
datacenter speed from slow seeds and flaky links, then hand you a fast, resumable
HTTPS link.

| Host              | Port | Component    | Auth                        |
| ----------------- | ---- | ------------ | --------------------------- |
| `dl.ony.world`    | -    | caddy files  | basic                       |
| `qb.ony.world`    | 8090 | qBittorrent  | basic, + path-token bypass  |
| `aria.ony.world`  | 6800 | aria2/AriaNg | basic                       |
| `jd.ony.world`    | 5800 | JDownloader  | the container's own         |

Everything downloads onto a 50G ext4 loop image at `/var/lib/seedbox.img`, mounted
at `/srv/seedbox`. The root LV claims `100%FREE`, so there are no extents for a new
LV and ext4 can't shrink online — an image file is the only cap that holds by
construction on a box we only reach over SSH. `dl.ony.world` serves that tree
directly, so nothing is ever copied twice.

`jd.ony.world` deliberately has no `basic_auth`: noVNC talks over a WebSocket and
browsers don't reliably attach cached basic-auth credentials to a WS handshake, so
the gate would 401 the console while looking like it worked. `WEB_AUTHENTICATION`
in the container is the real boundary there.

qBittorrent seeds, which publishes hizuru's IP to swarms and makes the VPS
provider's abuse contact the address of record for any notice. aria2 and
JDownloader only pull. Nothing here masks that; there is no VPN on this host.

## Bootstrap

DNS and the shared caddy env file are not declarative. Do both *before* the first
deploy — caddy does HTTP-01/TLS-ALPN with no DNS challenge configured, so cert
issuance fails on a missing record.

```sh
# 1. A records -> 94.250.201.16, by hand at the registrar:
#      dl.ony.world  qb.ony.world  aria.ony.world  jd.ony.world
```

```sh
# 2. On maki: the basic-auth pair and the token, appended to the shared caddy env
# file. SEEDBOX_PATH_TOKEN is the only thing guarding qBittorrent's API for
# clients that can't send basic auth, so give it real entropy.
nix run nixpkgs#caddy -- hash-password        # -> SEEDBOX_BASIC_HASH
openssl rand -hex 24                          # -> SEEDBOX_PATH_TOKEN

cd config/host/hizuru/users/ony/secrets
agenix -e caddy.age
#   SEEDBOX_BASIC_USER=...
#   SEEDBOX_BASIC_HASH=...
#   SEEDBOX_PATH_TOKEN=...
```

`aria2.age` (raw token, no `KEY=`) and `jdownloader.age`
(`WEB_AUTHENTICATION_USERNAME` / `WEB_AUTHENTICATION_PASSWORD`) already exist with
generated values. Read them back with `agenix -d <file>.age`, or replace them with
`agenix -e <file>.age`.

```sh
# 3. Deploy.
cd config && make
```

## AriaNg

AriaNg keeps the RPC secret in browser localStorage — it is not discovered. Seed it
once with the quick-setup route. Use `https`, not `wss`: browsers don't attach
cached basic-auth credentials to WebSocket handshakes, so `wss` 401s behind
`basic_auth`.

```sh
agenix -d aria2.age | base64 -w0    # the <token> below
```

```
https://aria.ony.world/#!/settings/rpc/set/https/aria.ony.world/443/jsonrpc/<token>
```

## Mobile torrent clients

qBitControl and Transdroid can't send basic auth, so point them at the token path
instead — base URL `https://qb.ony.world/<SEEDBOX_PATH_TOKEN>`. That door is
API-only: `handle_path` strips the prefix, so VueTorrent's absolute `/assets/*`
still 401s and the web UI won't load through it.
