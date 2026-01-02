{...}: {
  services.navidrome = {
    enable = true;
    user = "ony";
    settings = {
      MusicFolder = "/media/music";
    };
  };
}
