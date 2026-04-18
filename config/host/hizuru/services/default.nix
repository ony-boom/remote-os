{
  imports = [
    ./caddy.nix
    ./tailscale.nix
    ./umami.nix
    ./copyparty.nix # file server
    ./navidrome.nix
    ./filebrowser.nix

    ./webhooks
    # docker/podman containers as services
    ./containers
  ];
}
