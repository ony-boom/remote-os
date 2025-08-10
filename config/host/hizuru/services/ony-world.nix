{
  inputs,
  system,
  ...
}: let
  ony-world = inputs.ony-world.packages.${system}.default;
in {
  services.caddy.virtualHosts = {
    "ony.world" = {
      extraConfig = ''
        reverse_proxy http://localhost:4321
      '';
    };

    "www.ony.world" = {
      extraConfig = ''
        redir https://ony.world{uri} permanent
      '';
    };
  };

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
