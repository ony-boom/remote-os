{
  virtualisation.oci-containers.containers.deemix = {
    image = "ghcr.io/bambanah/deemix:latest";
    ports = [
      "6595:6595"
    ];
    volumes = [
      "/home/ony/Music:/downloads"
      "/home/ony/.config/deemix:/config"
    ];
  };
}
