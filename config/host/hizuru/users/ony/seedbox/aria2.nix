# Direct HTTP/FTP links: paste a URL, hizuru pulls it with parallel connections.
{
  config,
  pkgs,
  ...
}: let
  rpcPort = 6800;
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
      # rpc-listen-all defaults to false, so this stays on loopback.

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

  # AriaNg gets its own vhost rather than a path on dl.ony.world: its index.html
  # has no <base href> and uses relative asset paths, and /jsonrpc would be
  # shadowed the moment a download is named "jsonrpc". Same origin also means no
  # CORS and no rpc-allow-origin-all.
  #
  # AriaNg does not discover the RPC secret - it lives in browser localStorage.
  # Seed it once with the path-style quick-setup route (https, NOT wss: browsers
  # don't attach cached basic-auth credentials to WebSocket handshakes, so wss
  # 401s behind basic_auth):
  #   https://aria.ony.world/#!/settings/rpc/set/https/aria.ony.world/443/jsonrpc/<base64-of-token>
  services.caddy.virtualHosts."aria.ony.world".extraConfig = ''
    basic_auth {
      {$SEEDBOX_BASIC_USER} {$SEEDBOX_BASIC_HASH}
    }

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
