# Everything on hizuru that belongs to titosy: personal services, web vhosts,
# secrets. Mirror of ../ony. Add one file per service and import it below.
{config, ...}: {
  imports = [
    ./music.nix
  ];

  age.secrets.titosy-password.file = ./secrets/password.age;
  users.users.titosy.hashedPasswordFile = config.age.secrets.titosy-password.path;
}
