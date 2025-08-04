{
  config,
  lib,
  ...
}: {
  services.caddy.virtualHosts = lib.mkMerge [
    /*
       // Now managed in ony.world/devenv-setup
       // so no longer needed here, but for reference:
       {
      "devenv.ony.world" = {
        extraConfig = ''
          redir / https://raw.githubusercontent.com/ony-boom/home-manager/refs/heads/main/install.sh 302
        '';
      };
    }
    */
    (lib.mkIf config.services.mms.enable {
      "music.ony.world" = {
        extraConfig = ''
          reverse_proxy http://localhost:${toString config.services.mms.port}
        '';
      };
    })
  ];
}
