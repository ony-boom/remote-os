{config, ...}: {
  services.mms = {
    enable = true;
    host = "0.0.0.0";
  };

  services.caddy = {
    enable = true;

    virtualHosts."music.ony.world".extraConfig = ''
      reverse_proxy http://localhost:${builtins.toString config.services.mms.port}
    '';
  };

  networking.firewall.allowedTCPPorts = [config.services.mms.port 80 443];

  users.users.caddy = {
    isSystemUser = true;
    group = "caddy";
  };

  users.groups.caddy = {};
}
