{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ony-world.url = "github:ony-boom/ony.world";

    # No follows: keeps the colmena.cachix.org binary usable.
    colmena.url = "github:nix-community/colmena";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://ony-boom.cachix.org"
      "https://colmena.cachix.org"
    ];
    extra-trusted-public-keys = [
      "ony-boom.cachix.org-1:rPOTyyOCiAhLarertCrNnZLxsBFpcirEekoohcCZt10="
      "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
    ];
  };

  outputs = {
    nixpkgs,
    colmena,
    disko,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    apps.${system}.colmena = {
      type = "app";
      program = "${colmena.packages.${system}.colmena}/bin/colmena";
    };

    devShells.${system}.default = pkgs.mkShell {
      packages = [pkgs.just pkgs.opentofu];
    };

    # `nix fmt` passes no paths, and bare alejandra reads stdin.
    formatter.${system} = pkgs.writeShellScriptBin "fmt" ''
      exec ${pkgs.alejandra}/bin/alejandra "''${@:-.}"
    '';

    checks.${system}.lint =
      pkgs.runCommand "lint" {
        nativeBuildInputs = [pkgs.alejandra pkgs.deadnix pkgs.statix];
      } ''
        cd ${./.}
        alejandra --check .
        deadnix --fail --no-lambda-pattern-names .
        statix check -i host/hizuru/hardware-configuration.nix -i builder/hardware-configuration.nix .
        touch $out
      '';

    # Installed by builder/main.tf on new hosts; colmena takes over from there.
    nixosConfigurations.generic = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        disko.nixosModules.disko
        ./builder/configuration.nix
        ./builder/hardware-configuration.nix
      ];
    };

    colmenaHive = colmena.lib.makeHive {
      meta = {
        nixpkgs = import nixpkgs {
          inherit system;
          overlays = [];
        };
        specialArgs = {inherit inputs;};
      };

      defaults = import ./defaults;

      hizuru = import ./host/hizuru;
    };
  };
}
