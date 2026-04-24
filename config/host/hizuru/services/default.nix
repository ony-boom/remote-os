{
  imports = [
    ./caddy.nix
    ./tailscale.nix
    ./umami.nix
    ./copyparty.nix # file server
    ./navidrome.nix
    ./filebrowser.nix
    ./mmd.nix

    ./webhooks
    # docker/podman containers as services
    ./containers

    ./postgresql.nix
    ./mysql.nix
  ];
}
