{config, ...}: let
  inherit (config.services.umami.settings) HOSTNAME PORT;
in {
  age.secrets.umami.file = ./secrets/umami.age;

  services = {
    umami = {
      enable = true;
      settings.APP_SECRET_FILE = config.age.secrets.umami.path;
    };

    caddy.virtualHosts."umami.ony.world".extraConfig = ''
      reverse_proxy http://${HOSTNAME}:${toString PORT}
    '';
  };
}
