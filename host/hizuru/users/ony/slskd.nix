# Soulseek client, used by lidarr as indexer and download client.
{config, ...}: {
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
    };
  };
}
