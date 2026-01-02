{
  imports = [
    ./caddy.nix
    ./tailscale.nix
    ./umami.nix
    ./copyparty.nix # file server
    ./navidrome.nix

    ./webhooks
    # docker/podman containers as services
    ./containers
  ];
}
