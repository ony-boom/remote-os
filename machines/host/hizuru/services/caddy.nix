{
  config,
  lib,
  ...
}: {
  services.caddy.virtualHosts =
    {
      "devenv.ony.world" = {
        extraConfig = ''
          redir / https://raw.githubusercontent.com/ony-boom/home-manager/refs/heads/main/install.sh 302
        '';
      };
    }
    // lib.mkIf config.services.mms.enable {
      "music.ony.world" = {
        extraConfig = ''
          reverse_proxy http://localhost:${builtins.toString config.services.mms.port}
        '';
      };
    };
}
