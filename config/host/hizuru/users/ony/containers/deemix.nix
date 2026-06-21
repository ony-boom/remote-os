let
  port = "6595";
in {
  virtualisation.oci-containers.containers.deemix = {
    image = "ghcr.io/bambanah/deemix:latest";
    ports = [
      "127.0.0.1:${port}:${port}"
    ];

    environment = {
      PUID = "1000";
      PGID = "100";
    };

    volumes = [
      "/media/music:/downloads"
      "/home/ony/.config/deemix:/config"
    ];
    autoStart = true;
  };
}
