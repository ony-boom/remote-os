{
  fileSystems."/media/music" = {
    device = "/home/ony/Music";
    fsType = "none";
    options = ["bind"];
  };

  fileSystems."media/videos" = {
    device = "/home/ony/Videos";
    fsType = "none";
    options = ["bind"];
  };

  fileSystems."media/pictures" = {
    device = "/home/ony/Pictures";
    fsType = "none";
    options = ["bind"];
  };

  systemd.tmpfiles.rules = [
    "d /media/videos 0755 ony ony -"
    "Z /media/videos 0755 root root -"
  ];
}
