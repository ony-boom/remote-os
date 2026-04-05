{config, ...}: {
  age.secrets.copyparty.file = ../secrets/navidrome.age;
  services.navidrome = {
    environmentFile = config.age.secrets.navidrome.path;
    enable = true;
    user = "ony";
    settings = {
      MusicFolder = "/media/music";
    };
  };
}
