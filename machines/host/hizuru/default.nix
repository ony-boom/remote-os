{disko, ...}: {
  deployment = {
    targetHost = "94.250.201.16";
    targetUser = "root";
  };

  imports = [
    disko.nixosModules.disko
    ./configuration.nix
    ./hardware-configuration.nix
  ];
}
