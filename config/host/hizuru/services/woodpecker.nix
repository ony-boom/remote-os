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

  # Bumps a flake input on remote-os, applies it, then pushes the updated lock.
  # The agent runs as ${deployUser}, which has the GitHub-authorized SSH key and
  # NOPASSWD sudo (used for `colmena apply-local`).
  # Usage: deploy-flake-input <input-name> [commit-sha]
  deployFlakeInput = pkgs.writeShellApplication {
    name = "deploy-flake-input";
    runtimeInputs = with pkgs; [git nix];
    text = ''
      set -euo pipefail

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

  systemd.services.woodpecker-agent-local = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = deployUser;
      Group = "users";
    };
    path = ["/run/wrappers" deployFlakeInput] ++ (with pkgs; [nix git git-lfs bash coreutils]);
  };

  systemd.tmpfiles.rules = [
    "d ${remoteOsCheckout} 0755 ${deployUser} users - -"
  ];

  environment.systemPackages = [deployFlakeInput];

  services.caddy.virtualHosts."ci.ony.world".extraConfig = ''
    reverse_proxy http://127.0.0.1:${toString serverPort}
  '';
}
