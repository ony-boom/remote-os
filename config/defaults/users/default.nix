{inputs, ...}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager

    ./ony
    ./titosy
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs;};

    # Adopting HM onto a box with existing dotfiles: move clobbered files aside
    # (e.g. .zshrc -> .zshrc.hm-bak) instead of failing activation.
    backupFileExtension = "hm-bak";

    # HM master runs a release ahead of nixos-unstable's string; the check is a
    # false positive since HM follows our nixpkgs. Silence it for every user.
    sharedModules = [{home.enableNixpkgsReleaseCheck = false;}];
  };
}
