{disko, ...}: {
  deployment = {
    targetPort = 22;
    targetUser = "ony";
    targetHost = "94.250.201.16";

    buildOnTarget = true;
    allowLocalDeployment = true;
  };

  imports = [
    disko.nixosModules.disko
    ./configuration.nix
    ./hardware-configuration.nix
  ];
}
