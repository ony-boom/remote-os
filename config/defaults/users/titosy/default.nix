{pkgs, ...}: {
  users.users.titosy = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
    shell = pkgs.zsh;
    hashedPassword = "$6$rlEnH.9.J8fi1Kw2$o1MRrZoQxrQmRf2u2bXXLYLeygY815stnZY7zbsTTexQQmgJFwfM5SuP0LACWL0sj.T./JtAoSVdPRSOATXSS0";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfA9T74URZ3QKWGC1guq6+WJmhCqRh0LXQ1HeFJ6O4f dev.titosy@gmail.com"
    ];
  };

  nix.settings.trusted-users = ["titosy"];

  # Passwordless sudo so `colmena apply` can run the activation script as root.
  security.sudo.extraRules = [
    {
      users = ["titosy"];
      commands = [{command = "ALL"; options = ["NOPASSWD"];}];
    }
  ];

  home-manager.users.titosy = import ./home.nix;
}
