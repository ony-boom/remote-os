# Shared host infrastructure. Per-user services live in ../users/<name>.nix.
{
  imports = [
    ./tailscale.nix
  ];
}
