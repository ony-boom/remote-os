{
  name,
  ...
}: {
  imports = [
    ./defaults
  ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  programs.zsh.enable = true;

  # Ship terminfo for ghostty (and others) so zsh's zle works over SSH.
  environment.enableAllTerminfo = true;

  networking = {
    hostName = name;
    firewall = {
      allowedTCPPorts = [22 80 443];
    };
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = ["root" "deploy"];
      extra-substituters = [
        "https://ony-boom.cachix.org"
        # Caches maki needs hizuru to substitute from when building maki's
        # closure via `nixos-rebuild --build-host`.
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "ony-boom.cachix.org-1:rPOTyyOCiAhLarertCrNnZLxsBFpcirEekoohcCZt10="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      download-buffer-size = 524288000;
    };
  };

  security.sudo.extraRules = [
    {
      users = ["deploy"];
      commands = [
        {
          command = "/run/current-system/sw/bin/nix";
          options = ["NOPASSWD" "SETENV"];
        }
      ];
    }
  ];

  system.stateVersion = "25.05";
}
