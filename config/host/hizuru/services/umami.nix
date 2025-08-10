{config, ...}: {
  age.secrets.umami.file = ../secrets/umami.age;

  services.umami = {
    enable = true;
    settings = {
      APP_SECRET_FILE = config.age.secrets.umami.path;
    };
  };

  services.caddy.virtualHosts."umami.ony.world" = {
    extraConfig = ''
      reverse_proxy http://localhost:${toString config.services.umami.settings.PORT}
    '';
  };
}
