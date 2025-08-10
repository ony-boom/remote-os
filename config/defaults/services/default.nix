{
  imports = [
    ./caddy.nix
    ./docker.nix
  ];

  services.fail2ban.enable = true;
}
