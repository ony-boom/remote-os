# Wanted list for music; finds releases through slskd (Tubifarry plugin) and
# files them into the library navidrome serves.
{
  services.lidarr = {
    enable = true;
    user = "ony";
    group = "users";
    settings.server.bindaddress = "127.0.0.1";
  };
}
