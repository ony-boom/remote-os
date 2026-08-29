# Everything on hizuru that belongs to ony: personal services, web vhosts,
# and the /home/ony media mounts. titosy's host config would be a sibling dir.
{
  imports = [
    ./caddy.nix
    ./garage.nix
    ./navidrome.nix
    ./filebrowser.nix
    ./umami.nix
    ./languagetool.nix
    ./mysql.nix
    ./containers
    ./mounts.nix
  ];
}
