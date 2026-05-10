{config, ...}: let
  port = "5984";
in {
  age.secrets.couchdb.file = ../../secrets/couchdb.age;

  virtualisation.oci-containers.containers.couchdb = {
    image = "couchdb:3";
    environment = {
      COUCHDB_USER = "ony";
    };
    environmentFiles = [config.age.secrets.couchdb.path];
    ports = ["127.0.0.1:${port}:${port}"];
    volumes = ["/var/lib/couchdb:/opt/couchdb/data"];
  };

  services.caddy.virtualHosts."couchdb.ony.world".extraConfig = ''
    reverse_proxy http://127.0.0.1:${port}
  '';
}
