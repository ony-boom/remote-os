{
  pkgs,
  lib,
  inputs,
  config,
  ...
}: let
  simple-cd = inputs.simple-cd.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  age.secrets.simple-cd.file = ../secrets/simple-cd.age;

  systemd.services.simple-cd = {
    description = "Simple CD service";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      User = "ony";
      ExecStart = "${lib.getExe simple-cd}";
      Restart = "on-failure";

      Environment = [
        "NODE_ENV=production"
      ];
      EnvironmentFile = [
        config.age.secrets.simple-cd.path
      ];
    };
  };
}
