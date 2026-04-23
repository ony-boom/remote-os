{
  inputs,
  pkgs,
  lib,
  ...
}: let
  mmd = lib.getExe inputs.ony-world.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
      ExecStart = mmd;
      Restart = "on-failure";
      RestartSec = 5;
      User = "ony";
    };
  };
}
