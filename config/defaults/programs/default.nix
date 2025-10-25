{pkgs, ...}: {
  programs = {
    mosh.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
    };
  };

  environment.systemPackages = with pkgs; [
    gnumake
    bottom
    openssl
    neofetch
  ];
}
