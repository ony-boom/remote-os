{
  config,
  lib,
  pkgs,
  ...
}: let
  serverPort = 3007;

  remoteOsRepo = "git@github.com:ony-boom/remote-os.git";
  remoteOsCheckout = "/var/lib/remote-os";
  deployUser = "deploy";

  # Generic deploy: bumps a flake input on remote-os, applies, then pushes the lock.
  # The deploy user is resolved server-side — pipelines call this script without
  # naming the user. When invoked as anything other than ${deployUser}, the script
  # re-execs itself as that user via runuser. This keeps the user out of repo configs.
  # Usage: deploy-flake-input <input-name> [commit-sha]
  deployFlakeInput = pkgs.writeShellApplication {
    name = "deploy-flake-input";
    runtimeInputs = with pkgs; [git nix util-linux];
    text = ''
      set -euo pipefail

      if [ "$(id -un)" != "${deployUser}" ]; then
        exec runuser -u ${deployUser} -- "$0" "$@"
      fi

      if [ $# -lt 1 ]; then
        echo "usage: deploy-flake-input <input-name> [commit-sha]" >&2
        exit 2
      fi
      input="$1"
      commit="''${2:-}"
      if ! [[ "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "invalid input name: $input" >&2
        exit 2
      fi

      if [ ! -d ${remoteOsCheckout}/.git ]; then
        git clone ${remoteOsRepo} ${remoteOsCheckout}
      fi
      cd ${remoteOsCheckout}
      git fetch origin main
      git reset --hard origin/main

      cd config
      nix --accept-flake-config flake lock --update-input "$input"

      if git diff --quiet flake.lock; then
        echo "flake.lock unchanged for input '$input'; nothing to deploy."
        exit 0
      fi

      git add flake.lock
      git -c user.email=ci@ony.world -c user.name=woodpecker \
        commit -m "chore: updated $input to ''${commit:0:7}"
      git push origin main

      sudo -n nix --accept-flake-config run .\#apps.x86_64-linux.colmena apply-local
    '';
  };

  # Inputs the woodpecker agent is allowed to redeploy.
  deployableInputs = ["ony-world"];
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

  services.woodpecker-agents.agents.local = {
    enable = true;
    environment = {
      WOODPECKER_SERVER = "localhost:9000";
      WOODPECKER_BACKEND = "local";
      WOODPECKER_MAX_WORKFLOWS = "1";
    };
    environmentFile = [config.age.secrets.woodpecker.path];
  };

  users.users.woodpecker-agent = {
    isSystemUser = true;
    group = "woodpecker-agent";
    home = "/var/lib/woodpecker-agent";
    createHome = true;
  };
  users.groups.woodpecker-agent = {};

  systemd.services.woodpecker-agent-local = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "woodpecker-agent";
      Group = "woodpecker-agent";
    };
    path = with pkgs; [nix git bash coreutils];
  };

  systemd.tmpfiles.rules = [
    "d ${remoteOsCheckout} 0755 ${deployUser} users - -"
  ];

  security.sudo.extraRules = [
    {
      users = ["woodpecker-agent"];
      commands =
        map (input: {
          command = "${deployFlakeInput}/bin/deploy-flake-input ${input} *";
          options = ["NOPASSWD"];
        })
        deployableInputs;
    }
  ];

  environment.systemPackages = [deployFlakeInput];

  services.caddy.virtualHosts."ci.ony.world".extraConfig = ''
    reverse_proxy http://127.0.0.1:${toString serverPort}
  '';
}
