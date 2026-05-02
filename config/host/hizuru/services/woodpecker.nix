{config, ...}: {
  age.secrets.woodpecker.file = ../secrets/woodpecker.age;
  services.woodpecker-server = {
    enable = true;
    environment = {
      WOODPECKER_HOST = "https://ci.ony.world";
      WOODPECKER_SERVER_ADDR = ":3007";
      WOODPECKER_GRPC_ADDR = ":3008";
      WOODPECKER_OPEN = "true";
      WOODPECKER_GITHUB = "true";
    };

    environmentFile = config.age.secrets.woodpecker.path;
  };
}
