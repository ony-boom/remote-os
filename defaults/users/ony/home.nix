{pkgs, ...}: {
  home.packages = [pkgs.go];

  programs.git = {
    enable = true;
    settings.user = {
      name = "ony";
      email = "ony@ony.world";
    };
  };
}
