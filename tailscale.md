# Tailscale serve

`tailscale serve` is imperative: the mapping lives in tailscaled's own state, not
in this repo. A port published once stays published after the config that wanted
it is gone, and there is no record of why it exists.

[`config/host/hizuru/services/tailscale.nix`](config/host/hizuru/services/tailscale.nix)
makes it declarative. `services.tailscaleServe` is the single source of truth, and
`tailscale-serve.service` reconciles the node to it:

```
tailscale serve reset          # drops everything, funnel included
tailscale serve  --bg --yes --https=<port> <target>   # replayed per entry
tailscale funnel --bg --yes --https=<port> <target>   # when funnel = true
```

Adding an entry serves it; **removing one unserves it** on the next deploy. That
only works because the reset is unconditional, so every mapping that should exist
has to be declared — an undeclared port is removed, not left alone.

The unit's script text changes only when the set changes, so
`switch-to-configuration` restarts it then and not on unrelated deploys. The
window where nothing is served is a few seconds, and rare.

Each service declares its own mapping next to itself, the same way vhosts do:

```nix
# users/ony/filebrowser.nix
services.tailscaleServe."8080".target = "http://localhost:8080";
```

## Current mappings

| Port | Service     | Declared in                       | Reach          |
| ---- | ----------- | --------------------------------- | -------------- |
| 4533 | navidrome   | `users/ony/navidrome.nix`         | **public**     |
| 5800 | JDownloader | `users/ony/seedbox/jdownloader.nix` | tailnet      |
| 6595 | deemix      | `users/ony/containers/deemix.nix` | tailnet        |
| 7081 | AriaNg      | `users/ony/seedbox/aria2.nix`     | tailnet        |
| 8080 | filebrowser | `users/ony/filebrowser.nix`       | tailnet        |
| 8090 | qBittorrent | `users/ony/seedbox/qbittorrent.nix` | tailnet      |

navidrome is on **Funnel**, meaning it is reachable from the public internet and
navidrome's own login is the only thing guarding it. Everything else is tailnet
only. Set `funnel = false` in `navidrome.nix` to pull it back.
