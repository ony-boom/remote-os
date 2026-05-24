{
  name,
  pkgs,
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

  users.users = let
    publicKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+IhjgxWSqhWo6ER2Gw4qyRb5JS7ioJIAKRZFJaId/y ony@maki"
    ];
  in {
    ony = {
      isNormalUser = true;
      hashedPassword = "$6$74ywRZqjR0/lgpMb$Uwh2Ul9FNj/u.mLtYKPkxVUL0jEjcaVyhUZ84mFShv8gbonujR/cK2lNht0KOKJjMVZ/fVqI9XSLF910g/rNO/";
      extraGroups = ["wheel" "networkmanager"];
      openssh.authorizedKeys.keys =
        publicKeys
        ++ [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5iHdYragwwtS6KdS9chikFGk0EMSO06HTM1QA3YRMi gh-@hizuru"
        ];

      shell = pkgs.zsh;
    };
    root = {
      # shell = pkgs.zsh;
      openssh.authorizedKeys.keys = publicKeys;
    };
  };

  programs.zsh.enable = true;

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
      trusted-users = ["ony" "root" "deploy"];
      extra-substituters = [
        "https://ony-boom.cachix.org"
        # Caches maki needs hizuru to substitute from when building maki's
        # closure via `nixos-rebuild --build-host`.
        "https://nix-community.cachix.org"
        "https://fenix.cachix.org"
        "https://cuda-maintainers.cachix.org"
      ];
      extra-trusted-public-keys = [
        "ony-boom.cachix.org-1:rPOTyyOCiAhLarertCrNnZLxsBFpcirEekoohcCZt10="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "fenix.cachix.org-1:ecJhr+RdYEdcVgUkjruiYhjbBloIEGov7bos90cZi0Q="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
      download-buffer-size = 524288000;
    };
  };

  security.sudo.extraRules = [
    {
      users = ["ony"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
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
