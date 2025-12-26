{
  inputs,
  pkgs,
  config,
  ...
}: let
  ony-world = inputs.ony-world.packages.${pkgs.stdenv.hostPlatform.system}.default;
  umami-settings = config.services.umami.settings;
in {
  services.caddy.virtualHosts = {
    "ony.world" = {
      extraConfig = ''
        root * ${ony-world}/var/www/ony.world

        handle {
            file_server {
                pass_thru
            }

            encode zstd gzip

            # Try the path, then path.html
            # e.g. /projects → /projects.html
            try_files {path} {path}.html
        }

        # SECOND BLOCK — fallback to SvelteKit app (SPA behavior)
        handle {
            # Fallback to index.html (your build does not include `200.html`)
            rewrite * /index.html
            file_server
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


    "webhooks.ony.world" = {
      extraConfig = ''
        reverse_proxy http://127.0.0.1:3002
      '';
    };

    "aresthegreek.work" = {
      extraConfig = ''
        redir https://aresthegreek.framer.website{uri} 302
      '';
    };

    "www.aresthegreek.work" = {
      extraConfig = ''
        redir https://aresthegreek.framer.website{uri} 302
      '';
    };
  };
}
