{...}: {
  home.stateVersion = "25.05";

  programs = {
    git = {
      enable = true;
      settings.user = {
        name = "titosy";
        email = "dev.titosy@gmail.com"; # adjust
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
