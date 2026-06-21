{pkgs, ...}: let
  onyKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+IhjgxWSqhWo6ER2Gw4qyRb5JS7ioJIAKRZFJaId/y ony@maki";
in {
  users.users.ony = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
    shell = pkgs.zsh;
    hashedPassword = "$6$74ywRZqjR0/lgpMb$Uwh2Ul9FNj/u.mLtYKPkxVUL0jEjcaVyhUZ84mFShv8gbonujR/cK2lNht0KOKJjMVZ/fVqI9XSLF910g/rNO/";
    openssh.authorizedKeys.keys = [
      onyKey
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5iHdYragwwtS6KdS9chikFGk0EMSO06HTM1QA3YRMi gh-@hizuru"
    ];
  };

  # ony's key also grants root login.
  users.users.root.openssh.authorizedKeys.keys = [onyKey];

  nix.settings.trusted-users = ["ony"];

  security.sudo.extraRules = [
    {
      users = ["ony"];
      commands = [{command = "ALL"; options = ["NOPASSWD"];}];
    }
  ];

  home-manager.users.ony = import ./home.nix;
}
