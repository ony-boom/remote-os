{
  lib,
  modulesPath,
  ...
}: {
  deployment = {
    targetHost = "128.199.228.20";
    targetUser = "root";
  };

  imports =
    lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix
    ++ [
      (modulesPath + "/virtualisation/digital-ocean-config.nix")
    ];

  boot.isContainer = true;
  time.timeZone = "Asia/Singapore";
}
