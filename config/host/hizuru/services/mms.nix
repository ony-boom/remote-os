{config, ...}: {
  services.mms = {
    enable = true;
    user = "ony";
    host = "0.0.0.0";
  };

  services.caddy.virtualHosts."music.ony.world" = {
    extraConfig = ''
      reverse_proxy http://localhost:${toString config.services.mms.port}
    '';
  };
}
