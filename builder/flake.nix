{
  description = "A flake for managing my remote nixos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = {
      buildDoImage = let
        config = {
          imports = [
            "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
          ];
        };
      in
        (pkgs.nixos config).digitalOceanImage;
    };
  };
}
