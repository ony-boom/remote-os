{pkgs, ...}: {
  home.packages = with pkgs; [bottom];
  home.stateVersion = "25.05";
}

