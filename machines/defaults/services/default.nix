{
  imports = [
    ./caddy.nix
  ];

  services.fail2ban.enable = true;
}
