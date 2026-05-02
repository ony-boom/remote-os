{config, ...}: let
  serverPort = 3007;
in {
  age.secrets.woodpecker.file = ../secrets/woodpecker.age;
  services.woodpecker-server = {
    enable = true;
    environment = {
      WOODPECKER_HOST = "https://ci.ony.world";
      WOODPECKER_SERVER_ADDR = ":${toString serverPort}";
      WOODPECKER_OPEN = "true";
      WOODPECKER_GITHUB = "true";
    };

    environmentFile = config.age.secrets.woodpecker.path;
  };

  services.caddy.virtualHosts."ci.ony.world".extraConfig = ''
    reverse_proxy http://127.0.0.1:${toString serverPort}
  '';
}
