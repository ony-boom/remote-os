{config, ...}: {
  services.mms = {
    enable = true;
    host = "0.0.0.0";
  };

  services.caddy = {
    enable = true;

    virtualHosts."music.ony.world".extraConfig = ''
      @abusers {
        header User-Agent "bad-bot"
      }

      respond @abusers "Blocked" 403
      reverse_proxy http://localhost:${builtins.toString config.services.mms.port}
    '';
  };

  services.fail2ban.enable = true;
  networking.firewall.allowedTCPPorts = [80 443];

  users.users.caddy = {
    isSystemUser = true;
    group = "caddy";
  };

  users.groups.caddy = {};
}
