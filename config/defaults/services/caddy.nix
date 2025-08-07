{
  services.caddy = {
    enable = true;
  };

  users.users.caddy = {
    isSystemUser = true;
    group = "caddy";
  };

  users.groups.caddy = {};
}
