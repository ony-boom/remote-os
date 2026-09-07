{config, ...}: {
  age.secrets.navidrome.file = ./secrets/navidrome.age;
  services.navidrome = {
    environmentFile = config.age.secrets.navidrome.path;
    enable = true;
    user = "ony";
    settings = {
      MusicFolder = "/media/music";
    };
  };

  # Funnel, not plain serve: this one is reachable from the public internet, so
  # navidrome's own login is the only thing guarding it. Set funnel = false to
  # pull it back behind the tailnet.
  services.tailscaleServe."4533" = {
    target = "http://localhost:4533";
    funnel = true;
  };
}
