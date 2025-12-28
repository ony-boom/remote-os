{
  imports = [
    ./mms.nix
    ./caddy.nix
    ./tailscale.nix
    ./umami.nix
    ./copyparty.nix # file server

    ./webhooks
    # docker/podman containers as services
    ./containers
  ];
}
