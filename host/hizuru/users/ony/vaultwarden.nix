{config, ...}: let
  port = 8222;
in {
  # ADMIN_TOKEN (argon2 hash) and the plaintext it hashes, as a comment.
  # Read back with `agenix -d vaultwarden.age`.
  age.secrets.vaultwarden.file = ./secrets/vaultwarden.age;

  services.vaultwarden = {
    enable = true;
    environmentFile = config.age.secrets.vaultwarden.path;
    backupDir = "/var/backup/vaultwarden";
    config = {
      DOMAIN = "https://vault.ony.world";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = port;
      # Public vhost, so the account list is the allow list: create users from
      # /admin, or flip this on for one deploy.
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = true;
      SHOW_PASSWORD_HINT = false;
    };
  };

  services.caddy.virtualHosts."vault.ony.world".extraConfig = ''
    reverse_proxy http://127.0.0.1:${toString port}
    encode zstd gzip
  '';
}
