{
  disko,
  inputs,
  system,
  ...
}: {
  deployment = {
    targetHost = "94.250.201.16";
    targetUser = "ony";
  };

  imports = [
    disko.nixosModules.disko
    inputs.mms.nixosModules.${system}

    ./configuration.nix
    ./hardware-configuration.nix
  ];
}
