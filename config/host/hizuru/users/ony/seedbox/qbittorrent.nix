# Torrents. Bound to loopback, gated by caddy's basic_auth at qb.ony.world.
{pkgs, ...}: let
  # 8080 is filebrowser's default (../filebrowser.nix).
  webuiPort = 8090;
  torrentingPort = 51413;
in {
  services.qbittorrent = {
    enable = true;

    # The module only creates the group when it is literally "qbittorrent"
    # (groups = mkIf (cfg.group == "qbittorrent")), so seedbox is declared in
    # ./default.nix. It must stay qbittorrent's PRIMARY group: the unit sets
    # PrivateUsers=true, which maps only the unit's own uid and primary gid -
    # moving seedbox to SupplementaryGroups would break every group permission
    # check against /srv/seedbox.
    group = "seedbox";

    inherit webuiPort torrentingPort;

    # The module's openFirewall opens TCP only; DHT and uTP need UDP too, so the
    # ports are opened by hand below.
    openFirewall = false;

    # Written to qBittorrent.conf by an ExecStartPre `install` on every start, so
    # changes made in the web UI do not survive a restart - including the WebUI
    # password. That's fine here: LocalHostAuth is off and caddy's basic_auth is
    # the real boundary.
    serverConfig = {
      LegalNotice.Accepted = true;

      Preferences.WebUI = {
        AlternativeUIEnabled = true;
        RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
        Address = "127.0.0.1";
        Port = webuiPort;

        # caddy authenticates; qBittorrent trusts its loopback caller.
        LocalHostAuth = false;
        AuthSubnetWhitelistEnabled = true;
        AuthSubnetWhitelist = "127.0.0.1/32";
        HostHeaderValidation = false;

        # ReverseProxySupportEnabled MUST stay off. It makes qBittorrent read
        # X-Forwarded-For and see the real client IP, which is not loopback -
        # both the LocalHostAuth bypass and the whitelist above stop applying and
        # every request 401s.
      };

      BitTorrent.Session = {
        DefaultSavePath = "/srv/seedbox/torrents/complete";
        TempPath = "/srv/seedbox/torrents/incomplete";
        TempPathEnabled = true;
        Port = torrentingPort;

        GlobalMaxRatio = 2.0;
        # 5.x renamed MaxRatioAction to ShareLimitAction, and the value is a
        # string enum - writing 0 silently falls back to the default.
        ShareLimitAction = "Stop";
      };
    };
  };

  systemd.services.qbittorrent = {
    # 0002 so finished files are group-writable for ony.
    serviceConfig.UMask = "0002";
    # Without this the service can start before the loop image is mounted and
    # write into the (uncapped) root filesystem instead.
    unitConfig.RequiresMountsFor = "/srv/seedbox";
    after = ["seedbox-dirs.service"];
    requires = ["seedbox-dirs.service"];
  };

  networking.firewall = {
    allowedTCPPorts = [torrentingPort];
    allowedUDPPorts = [torrentingPort];
  };

  # Same two-handler shape as ../languagetool.nix, and for the same reason:
  # caddy runs basic_auth before handle/handle_path, so a top-level basic_auth
  # would gate the token path too.
  services.caddy.virtualHosts."qb.ony.world".extraConfig = ''
    # Escape hatch for mobile clients that can't send basic auth; point them at
    # https://qb.ony.world/{$SEEDBOX_PATH_TOKEN}. handle_path strips the prefix,
    # so VueTorrent's absolute /assets/* still 401s - this is an API-only door.
    # With LocalHostAuth off the token is the ONLY boundary, same threat model as
    # LT_PATH_TOKEN.
    handle_path /{$SEEDBOX_PATH_TOKEN}/* {
      reverse_proxy http://127.0.0.1:${toString webuiPort}
    }

    handle {
      basic_auth {
        {$SEEDBOX_BASIC_USER} {$SEEDBOX_BASIC_HASH}
      }

      reverse_proxy http://127.0.0.1:${toString webuiPort}
    }
  '';
}
