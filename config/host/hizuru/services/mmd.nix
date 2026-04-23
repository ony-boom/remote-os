{
  inputs,
  pkgs,
  lib,
  ...
}: let
  mmd = inputs.mmd.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  systemd.services.mmd = {
    description = "MMD Server";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    environment = {
      PORT = "3080";
      SPOTIFLAC_OUTPUT_DIR = "/media/music";
    };

    serviceConfig = {
      ExecStart = "${lib.getExe mmd}";
      Restart = "on-failure";
      RestartSec = 5;
      User = "ony";
      StateDirectory = "mmd";
      WorkingDirectory = "/var/lib/mmd";
    };
  };
}
