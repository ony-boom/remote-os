{
  config,
  lib,
  ...
}: {
  services.mms = {
    enable = true;
    user = "ony";
    host = "0.0.0.0";
  };

  services.caddy.virtualHosts = lib.mkIf config.services.mms.enable {
    "music.ony.world" = {
      extraConfig = ''
        reverse_proxy http://localhost:${builtins.toString config.services.mms.port}
      '';
    };
  };
}
