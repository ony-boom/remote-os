{
  imports = [
    ./mms.nix
    ./caddy.nix
    ./tailscale.nix
    ./copyparty.nix # file server

    # docker/podman containers as services
    ./containers
  ];
}
