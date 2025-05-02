{
  lib,
  modulesPath,
  mms,
  system,
  ...
}: {
  deployment = {
    targetHost = "167.99.70.7";
    targetUser = "root";
  };

  boot.isContainer = true;
  time.timeZone = "Asia/Singapore";

  imports =
    lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix
    ++ [
      (modulesPath + "/virtualisation/digital-ocean-config.nix")
      mms.nixosModules.${system}
      ./configuration.nix
    ];
}
