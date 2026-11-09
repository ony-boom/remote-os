# Home configuration shared by every user.
{
  home.stateVersion = "25.05";

  programs = {
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
