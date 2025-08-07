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

    ony-world = {
      url = "github:ony-boom/resume";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena.url = "github:zhaofengli/colmena";
  };

  outputs = {
    nixpkgs,
    disko,
    colmena,
    ...
  } @ inputs: let
    system = "x86_64-linux";
  in {
    apps.${system}.colmena = colmena.apps.${system}.colmena;
    colmenaHive = colmena.lib.makeHive {
      meta = {
        nixpkgs = import nixpkgs {
          inherit system;
          overlays = [];
        };
        specialArgs = {inherit inputs system disko;};
      };

      defaults = import ./configuration.nix;

      hizuru = import ./host/hizuru;
    };
  };
}
