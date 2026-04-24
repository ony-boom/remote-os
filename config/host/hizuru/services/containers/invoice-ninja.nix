{config, ...}: let
  port = "8090";
in {
  age.secrets.invoice-ninja.file = ../../secrets/invoice-ninja.age;

  virtualisation.oci-containers.containers.invoice-ninja = {
    image = "invoiceninja/invoiceninja:5";
    ports = [
      "127.0.0.1:${port}:80"
    ];

    environment = {
      APP_URL = "http://localhost:${port}";
      APP_DEBUG = "false";
      APP_ENV = "production";
      REQUIRE_HTTPS = "false";
      TRUSTED_PROXIES = "*";

      DB_CONNECTION = "pgsql";
      DB_HOST = "host.containers.internal";
      DB_PORT = "5432";
      DB_DATABASE = "invoiceninja";
      DB_USERNAME = "invoiceninja";

      MULTI_DB_ENABLED = "false";
      PUID = "1000";
      PGID = "100";
    };

    environmentFiles = [
      config.age.secrets.invoice-ninja.path
    ];

    volumes = [
      "/var/lib/invoice-ninja/public:/var/www/app/public"
      "/var/lib/invoice-ninja/storage:/var/www/app/storage"
    ];

    extraOptions = [
      "--add-host=host.containers.internal:host-gateway"
    ];

    autoStart = true;
  };
}
