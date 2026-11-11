# Everything on hizuru that belongs to ony.
{config, ...}: {
  imports = [
    ./caddy.nix
    ./garage.nix
    ./navidrome.nix
    ./slskd.nix
    ./beets.nix
    ./vaultwarden.nix
    ./filebrowser.nix
    ./umami.nix
    ./languagetool.nix
    ./mysql.nix
    ./containers
    ./mounts.nix
  ];

  age.secrets.ony-password.file = ./secrets/password.age;
  users.users.ony.hashedPasswordFile = config.age.secrets.ony-password.path;
}
