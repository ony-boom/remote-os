# Direct HTTP/FTP links: paste a URL, hizuru pulls it with parallel connections.
#
# aria2's RPC and the AriaNg UI both stay on loopback; `tailscale serve`
# publishes the UI to the tailnet (see seedbox.md), the same way filebrowser,
# deemix and navidrome are already published on this box.
{
  config,
  pkgs,
  ...
}: let
  rpcPort = 6800;
  # AriaNg plus the RPC proxy, bound to loopback for tailscale serve to pick up.
  uiPort = 7081;
in {
  age.secrets.aria2.file = ../secrets/aria2.age;

  services.aria2 = {
    enable = true;

    # Unlike caddy.age this file holds the RAW token, not KEY=value - the module
    # passes it through LoadCredential and appends `rpc-secret=$(cat ...)`.
    rpcSecretFile = config.age.secrets.aria2.path;

    # The module hardcodes User/Group = "aria2" and owns settings.dir through its
    # own tmpfiles rule, so downloads land aria2:aria2 no matter what groups the
    # user is in. Rather than fight that: 2775 here plus the default 0022 umask
    # gives 0644 files that caddy reads as itself. Raising serviceUMask would
    # force caddy into the aria2 group, which would also expose
    # /var/lib/aria2/aria2.conf - where the module writes rpc-secret in clear.
    downloadDirPermission = "2775";

    settings = {
      dir = "/srv/seedbox/http";
      rpc-listen-port = rpcPort;
      # rpc-listen-all defaults to false, so this stays on loopback and caddy is
      # the only thing that reaches it.

      # HTTP/FTP only; torrents are qBittorrent's job and DHT here would just
      # fight it for ports.
      enable-dht = false;
      bt-enable-lpd = false;
      follow-torrent = false;

      continue = true;
      max-connection-per-server = 8;
    };

    openPorts = false;
  };

  systemd.services.aria2 = {
    unitConfig.RequiresMountsFor = "/srv/seedbox";
    # seedbox-dirs, not just the mount: the module tmpfiles rule for settings.dir
    # runs pre-mount and gets shadowed, so the real /srv/seedbox/http is the one
    # seedbox-dirs creates on the image.
    after = ["seedbox-dirs.service"];
    requires = ["seedbox-dirs.service"];
  };

  users.users.ony.extraGroups = ["aria2"];

  services.tailscaleServe."${toString uiPort}".target = "http://127.0.0.1:${toString uiPort}";

  # Bound to loopback, so this needs no firewall rule and is not reachable from
  # the public interface at all. AriaNg is served at / rather than under a path:
  # its index.html has no <base href> and uses relative asset paths, so a
  # stripped prefix breaks it. Serving the UI and proxying the RPC from one
  # origin also means no CORS and no rpc-allow-origin-all.
  #
  # AriaNg does not discover the RPC secret - it lives in browser localStorage.
  # Seed it once with the path-style quick-setup route; see seedbox.md.
  services.caddy.virtualHosts."http://:${toString uiPort}".extraConfig = ''
    # http:// and an explicit bind, both load-bearing. A site address of
    # "127.0.0.1:7081" makes caddy turn on automatic HTTPS with an internal cert
    # for that port, and tailscaled forwards plain http - which lands as a 400.
    # The scheme prefix keeps it plain http; bind is what actually restricts the
    # listener, since the host in a site address only matches, it does not bind.
    bind 127.0.0.1

    handle /jsonrpc* {
      reverse_proxy http://127.0.0.1:${toString rpcPort}
    }

    handle {
      root * ${pkgs.ariang}/share/ariang

      encode zstd gzip
      file_server
    }
  '';
}
