{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.etc."webhooks" = {
    source = ./config;
  };

  age.secrets.webhooks.file = ../../secrets/webhooks.age;

  systemd.services.webhooks = {
    description = "Hizuru's webhooks listener";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.webhook} -ip 127.0.0.1 -template -verbose -hooks /etc/webhooks/hooks";
      User = "ony";
      Group = "users";

      # Use system wrappers for sudo
      Environment = "PATH=/run/wrappers/bin:${lib.makeBinPath (with pkgs; [
        bash
        git
        openssh
        nix
        gnumake
        coreutils
      ])}";

      EnvironmentFile = config.age.secrets.webhooks.path;
    };
  };
}
