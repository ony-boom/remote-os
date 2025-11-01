{
  inputs,
  pkgs,
  ...
}: let
  ony-world = inputs.ony-world.packages.${pkgs.system}.default;
in {
  services.caddy.virtualHosts = {
    ":80" = {
      extraConfig = ''
        root * ${ony-world}/var/www/ony.world
        file_server
      '';
    };
  };
}
