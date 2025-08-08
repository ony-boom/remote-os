{pkgs, ...}: {
  programs = {
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
