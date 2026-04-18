{modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    ./services
    ./programs
  ];

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

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
