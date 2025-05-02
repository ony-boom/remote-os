{
  lib,
  modulesPath,
  mms,
  system,
  config,
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
      mms.nixosModules.${system}
    ];

  services.mms = {
    enable = true;
    host = "0.0.0.0";
  };

  networking.firewall.allowedTCPPorts = [config.services.mms.port];

  boot.isContainer = true;
  time.timeZone = "Asia/Singapore";
}
