{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mms = {
      url = "github:ony-boom/mms";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://ony-boom.cachix.org"
    ];
    extra-trusted-public-keys = [
      "ony-boom.cachix.org-1:rPOTyyOCiAhLarertCrNnZLxsBFpcirEekoohcCZt10="
    ];
  };

  outputs = {
    nixpkgs,
    mms,
    disko,
    ...
  }: let
    system = "x86_64-linux";
  in {
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          inherit system;
          overlays = [];
        };
        specialArgs = {inherit mms system disko;};
      };

      defaults = import ./configuration.nix;

      ina = import ./host;

      hizuru = import ./host;
    };
  };
}
