{config, ...}: let
  umami-settings = config.services.umami.settings;
in {
  age.secrets.umami.file = ../secrets/umami.age;

  services.umami = {
    enable = true;

    settings = {
      APP_SECRET_FILE = config.age.secrets.umami.path;
    };
  };

  services.caddy.virtualHosts."umami.ony.world".extraConfig = ''
    reverse_proxy http://${umami-settings.HOSTNAME}:${toString umami-settings.PORT}
  '';
}
