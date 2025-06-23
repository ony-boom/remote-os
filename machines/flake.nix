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

      hizuru = import ./host/hizuru;
    };
  };
}
