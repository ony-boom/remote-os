{pkgs, ...}: {
  programs = {
    mosh.enable = true;
    zsh.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
    };
  };

  environment = {
    # Ship terminfo for ghostty (and others) so zsh's zle works over SSH.
    enableAllTerminfo = true;

    systemPackages = [
      pkgs.gnumake
      pkgs.bottom
      pkgs.openssl
      pkgs.ffmpeg
      pkgs.fastfetch
    ];
  };
}
