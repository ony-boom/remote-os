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

        # Rewrite clean URLs to their .html equivalents
        # Example:
        #   /projects → /projects.html
        #   /projects/my-music-server → /projects/my-music-server.html
        @html_no_ext path_regexp html_no_ext ^(.+?)/?$
        rewrite @html_no_ext {1}.html

        # Fallback behavior:
        # - if a file exists: serve it
        # - if a folder contains index.html: serve it
        # - else fallback to /index.html (SPA routes)
        try_files {path} {path}/index.html /index.html

        file_server      '';
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
