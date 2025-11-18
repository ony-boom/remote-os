{
  inputs,
  pkgs,
  config,
  ...
}: let
  ony-world = inputs.ony-world.packages.${pkgs.system}.default;
  umami-settings = config.services.umami.settings;
in {
  services.caddy.virtualHosts = {
    "ony.world" = {
      extraConfig = ''
        root * ${ony-world}/var/www/ony.world
        file_server

        handle {
          try_files {path} {path}/ index.html
        }
      '';
    };
    "www.ony.world" = {
      extraConfig = ''
        redir https://ony.world{uri}
      '';
    };

    "umami.ony.world" = {
      extraConfig = ''
        reverse_proxy http://${umami-settings.HOSTNAME}:${toString umami-settings.PORT}
      '';
    };

    "file.ony.world" = {
      extraConfig = ''
        reverse_proxy http://127.0.0.1:3923
      '';
    };
  };
}
