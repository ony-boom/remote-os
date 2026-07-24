{config, ...}: let
  port = "7080";
  # Host MariaDB (see ../mysql.nix) reached from the container over the
  # docker0 bridge. mysql.nix binds 0.0.0.0 and opens docker0:3306.
  dbHost = "172.17.0.1";
in {
  # Secret env file: APP_KEY (base64:...), DB_PASSWORD, IN_USER_EMAIL,
  # IN_PASSWORD, and any MAIL_* creds. Edit with `agenix -e invoice-ninja.age`.
  age.secrets.invoice-ninja.file = ../secrets/invoice-ninja.age;

  virtualisation.oci-containers.containers.invoice-ninja = {
    image = "invoiceninja/invoiceninja-debian:5";
    environment = {
      APP_ENV = "production";
      APP_DEBUG = "false";
      APP_URL = "https://invoicing.ony.world";
      REQUIRE_HTTPS = "false"; # Caddy terminates TLS in front of us.
      TRUSTED_PROXIES = "*";
      PDF_GENERATOR = "snappdf";
      PHANTOMJS_PDF_GENERATION = "false";
      DB_CONNECTION = "mysql";
      DB_HOST = dbHost;
      DB_PORT = "3306";
      DB_DATABASE = "invoiceninja";
      DB_USERNAME = "invoiceninja";
      QUEUE_CONNECTION = "sync"; # ponytail: no worker; switch to redis if queues get heavy.
    };
    environmentFiles = [config.age.secrets.invoice-ninja.path];
    ports = ["127.0.0.1:${port}:80"];
    volumes = [
      "/var/lib/invoice-ninja/public:/var/www/html/public"
      "/var/lib/invoice-ninja/storage:/var/www/html/storage"
    ];
    autoStart = true;
  };

  # ensureUsers in mysql.nix creates invoiceninja@localhost with socket auth
  # only. The container connects over TCP, so grant a %-host user a password
  # from the same secret. Idempotent; re-runs on every mysql (re)start.
  systemd.services.invoice-ninja-db-password = {
    after = ["mysql.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    serviceConfig.EnvironmentFile = config.age.secrets.invoice-ninja.path;
    # ponytail: CREATE IF NOT EXISTS is enough; to rotate the password later,
    # add an ALTER USER line or just drop the user first.
    script = ''
      ${config.services.mysql.package}/bin/mysql -e "
        CREATE USER IF NOT EXISTS 'invoiceninja'@'%' IDENTIFIED BY '$DB_PASSWORD';
        GRANT ALL PRIVILEGES ON invoiceninja.* TO 'invoiceninja'@'%';"
    '';
  };

  services.caddy.virtualHosts."invoicing.ony.world".extraConfig = ''
    reverse_proxy http://127.0.0.1:${port}
  '';
}
