{
  imports = [
    ./mms.nix
    ./caddy.nix
    ./tailscale.nix
    ./umami.nix
    ./copyparty.nix # file server

    # docker/podman containers as services
    ./containers
  ];
}
