{
  imports = [
    ./mms.nix
    ./caddy.nix
    ./tailscale.nix
    ./umami.nix
    ./copyparty.nix # file server
    # ./simple-cd.nix # webhook listener for auto deployment

    # docker/podman containers as services
    ./containers
  ];
}
