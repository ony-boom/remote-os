{pkgs, ...}: {
  home.stateVersion = "25.05";
  home.packages = [pkgs.go];

  programs = {
    git = {
      enable = true;
      settings.user = {
        name = "ony";
        email = "ony@ony.world"; # adjust
      };
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
    };

    starship.enable = true;

    atuin = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
