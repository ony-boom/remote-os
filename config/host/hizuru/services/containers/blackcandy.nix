let
  port = "3537";
in {
  virtualisation.oci-containers.containers.blackcandy = {
    image = "ghcr.io/blackcandy-org/blackcandy:latest ";
    ports = [
      "${port}:80"
    ];

    volumes = [
      "/home/ony/Music:/media_data"
      "/home/ony/.local/share/blackcandy:/app/storage"
    ];

    environment = {
      MEDIA_PATH = "/media_data";
    };

    autoStart = true;
  };
}
