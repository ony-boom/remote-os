{config, ...}: {
  services.mms = {
    enable = true;
    host = "0.0.0.0";
  };

  services.caddy = {
    enable = true;

    virtualHosts."music.ony.world" = {
      reverseProxy = "http://localhost:3536";

      extraConfig = ''
        encode gzip
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [config.services.mms.port 80 443];

  users.users.caddy = {
    isSystemUser = true;
    group = "caddy";
  };

  users.groups.caddy = {};
}
