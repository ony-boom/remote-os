{config, ...}: {
  services.mms = {
    enable = true;
    host = "0.0.0.0";
  };

  services.caddy.virtualHosts = {
    "music.ony.world".extraConfig = ''
      reverse_proxy http://localhost:${builtins.toString config.services.mms.port}
    '';
  };
}
