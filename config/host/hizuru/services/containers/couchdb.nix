{config, ...}: {
  age.secrets.couchdb.file = ../../secrets/couchdb.age;

  virtualisation.oci-containers.containers.couchdb = {
    image = "couchdb:3";
    environment = {
      COUCHDB_USER = "ony";
    };
    environmentFiles = [config.age.secrets.couchdb.path];
    ports = ["127.0.0.1:5984:5984"];
    volumes = ["/var/lib/couchdb:/opt/couchdb/data"];
  };
}
