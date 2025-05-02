{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hm = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mms = {
      url = "github:ony-boom/mms";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    hm,
    mms,
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
        specialArgs = {inherit hm mms system;};
      };

      defaults = import ./configuration.nix;

      ina = import ./host;
    };
  };
}
