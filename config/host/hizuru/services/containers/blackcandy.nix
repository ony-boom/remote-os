let
  port = "3537";
in {
  virtualisation.oci-containers.containers.blackcandy = {
    image = "ghcr.io/blackcandy-org/blackcandy:latest ";
    ports = [
      "127.0.0.1:${port}:${port}"
    ];

    /*
       environment = {
      MEDIA_PATH = "/home/ony/Music";
    };
    */
    autoStart = true;
  };
}
