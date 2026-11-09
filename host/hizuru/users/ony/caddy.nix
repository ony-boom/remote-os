{
  config,
  inputs,
  pkgs,
  ...
}: let
  ony-world = inputs.ony-world.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  # Caddyfile env vars ({$VAR}), decrypted by agenix; shared by every vhost.
  age.secrets.caddy.file = ./secrets/caddy.age;
  services.caddy.environmentFile = config.age.secrets.caddy.path;

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

    # Sveltia CMS: a static SPA shipped in the ony-world package, served from
    # its own root so /admin doesn't exist on the site. It holds no authority
    # of its own — GitHub decides who can write to the repo — so basic_auth is
    # here to keep crawlers and randoms off the page, not as the real boundary.
    # CMS_BASIC_USER/CMS_BASIC_HASH come from the caddy.age secret.
    "cms.ony.world" = {
      extraConfig = ''
        basic_auth {
          {$CMS_BASIC_USER} {$CMS_BASIC_HASH}
        }

        root * ${ony-world}/var/www/cms.ony.world

        encode zstd gzip
        file_server
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
