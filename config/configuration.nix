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
      trusted-substituters = [
        "https://ony-boom.cachix.org"
      ];
      trusted-public-keys = [
        "ony-boom.cachix.org-1:rPOTyyOCiAhLarertCrNnZLxsBFpcirEekoohcCZt10="
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
