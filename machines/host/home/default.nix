{
  mms,
  system,
  ...
}: {
  imports = [
    mms.homeManagerModules.${system}
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.ony = {
    programs.mms.enable = true;
  };
}

