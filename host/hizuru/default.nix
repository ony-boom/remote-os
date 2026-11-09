{
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disk-config.nix
    ./hardware-configuration.nix
    ./tailscale.nix
    ./users/ony
    ./users/titosy
  ];

  deployment = {
    # null = connect as whoever runs colmena (ony, titosy, ...), each with
    # their own account + key. CI pins `User ony` via ssh config.
    targetUser = null;
    targetHost = "94.250.201.16";

    buildOnTarget = true;
    allowLocalDeployment = true;
  };

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
