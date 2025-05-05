{
  lib,
  modulesPath,
  mms,
  system,
  ...
}: {
  deployment = {
    targetHost = "104.248.151.237";
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
