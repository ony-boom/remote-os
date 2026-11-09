{
  inputs,
  name,
  ...
}: {
  imports = [
    inputs.agenix.nixosModules.default

    ./programs.nix
    ./services.nix
    ./users
  ];

  networking.hostName = name;

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
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

  # So `colmena apply` can run the activation script as root.
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.05";
}
