{pkgs, ...}: let
  onyKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+IhjgxWSqhWo6ER2Gw4qyRb5JS7ioJIAKRZFJaId/y ony@maki"
  ];
in {
  users.users.ony = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys =
      onyKeys
      ++ [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5iHdYragwwtS6KdS9chikFGk0EMSO06HTM1QA3YRMi gh-@hizuru"
      ];
  };

  # ony's key also grants root login.
  users.users.root.openssh.authorizedKeys.keys = onyKeys;

  nix.settings.trusted-users = ["ony"];

  home-manager.users.ony = ./home.nix;
}
