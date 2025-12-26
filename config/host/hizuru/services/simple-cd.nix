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
        "PATH=/run/current-system/sw/bin"
        "NODE_ENV=production"
      ];
      EnvironmentFile = [
        config.age.secrets.simple-cd.path
      ];
    };
  };
}
