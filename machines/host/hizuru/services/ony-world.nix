{
  inputs,
  system,
  ...
}: let
  ony-world = inputs.ony-world.packages.${system}.default;
in {
  systemd.services.ony-world = {
    description = "Personal website and blog";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${ony-world}/bin/ony-world";
      Restart = "on-failure";
    };
  };
}
