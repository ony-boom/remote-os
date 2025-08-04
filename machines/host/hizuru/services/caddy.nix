{
  config,
  lib,
  ...
}: {
  services.caddy.virtualHosts = lib.mkMerge [
    {
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
    }
    (lib.mkIf config.services.mms.enable {
      "music.ony.world" = {
        extraConfig = ''
          reverse_proxy http://localhost:${toString config.services.mms.port}
        '';
      };
    })
  ];
}
