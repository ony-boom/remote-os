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
