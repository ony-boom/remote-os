let
  port = "6595";
in {
  virtualisation.oci-containers.containers.deemix = {
    image = "ghcr.io/bambanah/deemix:latest";
    ports = [
      "127.0.0.1:${port}:${port}"
    ];
    volumes = [
      "/home/ony/Music:/downloads"
      "/home/ony/.config/deemix:/config"
    ];
    autoStart = true;
  };
}
