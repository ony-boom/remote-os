{
  config,
  lib,
  ...
}: let
  website = {
    "ony.world" = {
      extraConfig = ''
        reverse_proxy http://localhost:4321
      '';
    };

    # Redirect www.ony.world → ony.world
    "www.ony.world" = {
      extraConfig = ''
        redir https://ony.world{uri} permanent
      '';
    };
  };

  music = {
    "music.ony.world" = {
      extraConfig = ''
        reverse_proxy http://localhost:${toString config.services.mms.port}
      '';
    };
  };

  anlytics = {
    "umami.ony.world" = {
      extraConfig = ''
        reverse_proxy http://localhost:${toString config.services.umami.settings.PORT}
      '';
    };
  };

  webhook = {
    "webhook.ony.world" = {
      extraConfig = ''
        reverse_proxy http://127.0.0.1:9000
      '';
    };
  };
in {
  services.caddy.virtualHosts = lib.mkMerge [
    website
    anlytics
    webhook
    (lib.mkIf config.services.mms.enable music)
  ];
}
