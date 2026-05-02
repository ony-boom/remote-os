{pkgs, ...}: {
  programs = {
    git = {
      enable = true;
      config = {
        user = {
          name = "Hizuru";
          email = "hizuru@ony.world";
        };
      };
    };

    zsh = {
      enableCompletion = true;
      syntaxHighlighting.enable = true;

      shellInit = ''
        eval "$(atuin init zsh)"
      '';
    };

    starship.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      go
      atuin
    ];
  };
}
