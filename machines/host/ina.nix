{
  lib,
  modulesPath,
  hm,
  mms,
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
      ./home
    ];

  boot.isContainer = true;
  time.timeZone = "Asia/Singapore";
}
