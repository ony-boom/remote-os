# Torrents. Nothing but the BitTorrent port is public.
#
# The web UI is reached over the tailnet with `tailscale serve` (see seedbox.md),
# which is already how filebrowser, deemix and navidrome are published on this
# box. That keeps qBittorrent on loopback, needs no firewall rule, and gets a
# real cert for hizuru.tempel-goblin.ts.net.
#
# Deliberately not a public vhost: the web UI can run an external program when a
# torrent finishes, so whoever gets past the front door gets command execution as
# the qbittorrent user - too much to hang on one basic_auth. The tailnet is
# device-level WireGuard keys instead, and mobile clients need no token hack.
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
    # password. That's fine here: nothing authenticates at this layer, the
    # tailnet does.
    serverConfig = {
      LegalNotice.Accepted = true;

      Preferences.WebUI = {
        AlternativeUIEnabled = true;
        RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
        Address = "127.0.0.1";
        Port = webuiPort;

        # tailscaled proxies from 127.0.0.1, so the bypass still applies.
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

  services.tailscaleServe."8090".target = "http://localhost:8090";

  networking.firewall = {
    # BitTorrent is the only part of this that faces the internet.
    allowedTCPPorts = [torrentingPort];
    allowedUDPPorts = [torrentingPort];
  };
}
