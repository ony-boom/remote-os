{
  lib,
  modulesPath,
  hm,
  ...
}: {
  deployment = {
    targetHost = "167.99.70.7";
    targetUser = "root";
  };

  imports =
    lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix
    ++ [
      (modulesPath + "/virtualisation/digital-ocean-config.nix")
      hm.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.ony = import ./home;
      }
    ];

  boot.isContainer = true;
  time.timeZone = "Asia/Singapore";
}
