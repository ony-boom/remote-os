{
  name,
  pkgs,
  ...
}: {
  imports = [
    ./defaults
  ];

  services.openssh.enable = true;

  users.users = let
    publicKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+IhjgxWSqhWo6ER2Gw4qyRb5JS7ioJIAKRZFJaId/y ony@maki"

      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC1M4MDbwNVI0Kaiqh2X1L/gPeUASYca0eEV9Ip0Uo/B github-actions@hizuru"
    ];
  in {
    ony = {
      isNormalUser = true;
      hashedPassword = "$6$74ywRZqjR0/lgpMb$Uwh2Ul9FNj/u.mLtYKPkxVUL0jEjcaVyhUZ84mFShv8gbonujR/cK2lNht0KOKJjMVZ/fVqI9XSLF910g/rNO/";
      extraGroups = ["wheel" "networkmanager"];
      openssh.authorizedKeys.keys = publicKeys;

      shell = pkgs.zsh;
    };
    root = {
      # shell = pkgs.zsh;
      openssh.authorizedKeys.keys = publicKeys;
    };

    deploy = {
      isNormalUser = true;
      description = "GitHub Actions deployment user";
      extraGroups = [
        "wheel"
      ];
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

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = ["ony" "root"];
      trusted-substituters = [
        "https://ony-boom.cachix.org"
      ];
      trusted-public-keys = [
        "ony-boom.cachix.org-1:rPOTyyOCiAhLarertCrNnZLxsBFpcirEekoohcCZt10="
      ];
    };
  };

  security.sudo.extraRules = [
    {
      users = ["ony" "deploy"];
      commands = [
        {
          command = "ALL";
          options = [
            "NOPASSWD"
          ];
        }
      ];
    }
  ];

  system.stateVersion = "25.05";
}
