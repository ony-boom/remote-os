# Soulseek client; search and download single tracks from its web UI. beets
# files finished downloads into the library.
{
  config,
  pkgs,
  ...
}: {
  age.secrets.slskd.file = ./secrets/slskd.age;

  services.slskd = {
    enable = true;
    user = "ony";
    group = "users";
    # SLSKD_SLSK_USERNAME, SLSKD_SLSK_PASSWORD, SLSKD_USERNAME, SLSKD_PASSWORD,
    # SLSKD_API_KEY.
    environmentFile = config.age.secrets.slskd.path;
    # Soulseek listen port, so peers can connect for uploads and searches.
    openFirewall = true;
    settings = {
      web.ip_address = "127.0.0.1";
      shares.directories = ["/media/music"];
      # Starts beets-import, see beets.nix.
      integrations.scripts.beets.on = ["DownloadFileComplete"];
      integrations.scripts.beets.run = {
        executable = "${pkgs.coreutils}/bin/touch";
        arglist = ["/var/lib/slskd/import-pending"];
      };
    };
  };
}
