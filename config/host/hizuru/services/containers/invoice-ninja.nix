{config, ...}: let
  port = "8090";
in {
  age.secrets.invoice-ninja.file = ../../secrets/invoice-ninja.age;

  systemd.tmpfiles.rules = [
    "d /var/lib/invoice-ninja         0755 1500 1500 -"
    "d /var/lib/invoice-ninja/public  0755 1500 1500 -"
    "d /var/lib/invoice-ninja/storage 0755 1500 1500 -"
  ];

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

      DB_CONNECTION = "mysql";
      DB_HOST = "host.containers.internal";
      DB_PORT = "3306";
      DB_DATABASE = "invoiceninja";
      DB_USERNAME = "invoiceninja";

      MULTI_DB_ENABLED = "false";
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
