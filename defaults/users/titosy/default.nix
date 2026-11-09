{pkgs, ...}: {
  users.users.titosy = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfA9T74URZ3QKWGC1guq6+WJmhCqRh0LXQ1HeFJ6O4f dev.titosy@gmail.com"
    ];
  };

  nix.settings.trusted-users = ["titosy"];

  home-manager.users.titosy = ./home.nix;
}
