{
  mms,
  system,
  ...
}: {
  imports = [
    mms.homeManagerModules.${system}
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useGlobalPkgs = true;

  home-manager.users.ony = {
    home.stateVersion = "25.05";

    programs.mms.enable = true;
  };
}

