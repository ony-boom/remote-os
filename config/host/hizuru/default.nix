{
  disko,
  inputs,
  ...
}: {
  deployment = {
    targetPort = 22;
    # null = connect as whoever runs colmena (ony, titosy, ...), each with
    # their own account + key. CI pins `User ony` via ssh config.
    targetUser = null;
    targetHost = "94.250.201.16";

    buildOnTarget = true;
    allowLocalDeployment = true;
  };

  imports = [
    disko.nixosModules.disko
    inputs.copyparty.nixosModules.default
    {
      nixpkgs.overlays = [inputs.copyparty.overlays.default];
    }

    ./configuration.nix
    ./hardware-configuration.nix
  ];
}
