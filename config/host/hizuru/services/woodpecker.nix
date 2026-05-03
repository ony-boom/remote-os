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

  flakeDeployTriggerDir = "/var/lib/flake-deploy";
  flakeDeployTrigger = "${flakeDeployTriggerDir}/trigger";

  # Bumps a flake input on remote-os, pushes the updated lock, and queues a
  # local apply via the flake-deploy.service systemd unit. The actual rebuild
  # runs detached from this script so an activation that restarts the agent
  # mid-run does not kill the deploy itself.
  # Usage: deploy-flake-input <input-name> [commit-sha]
  deployFlakeInput = pkgs.writeShellApplication {
    name = "deploy-flake-input";
    runtimeInputs = with pkgs; [git nix openssh coreutils];
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

      export GIT_SSH_COMMAND="ssh -i ${config.age.secrets.deploy-ssh-key.path} -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/home/${deployUser}/.ssh/known_hosts"

      if [ ! -d ${remoteOsCheckout}/.git ]; then
        git clone ${remoteOsRepo} ${remoteOsCheckout}
      fi
      cd ${remoteOsCheckout}
      git fetch origin main
      git reset --hard origin/main

      cd config
      nix --accept-flake-config flake update "$input"

      if git diff --quiet flake.lock; then
        echo "flake.lock unchanged for input '$input'; nothing to deploy."
        exit 0
      fi

      git add flake.lock
      git -c user.email=ci@ony.world -c user.name=woodpecker \
        commit -m "chore: updated $input to ''${commit:0:7}"

      echo "==> pushing to origin/main..."
      if ! git push origin main 2>&1; then
        echo "==> push failed; pulling --rebase and retrying..."
        git pull --rebase origin main 2>&1
        git push origin main 2>&1
      fi

      echo "==> queueing flake-deploy.service via ${flakeDeployTrigger}"
      date -u +%FT%TZ > ${flakeDeployTrigger}
      echo "==> done. Watch progress with: journalctl -u flake-deploy.service -f"
    '';
  };
in {
  age.secrets.woodpecker.file = ../secrets/woodpecker.age;

  age.secrets.deploy-ssh-key = {
    file = ../secrets/deploy-ssh-key.age;
    mode = "0400";
    owner = deployUser;
    group = "users";
  };

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
      NoNewPrivileges = lib.mkForce false;
      ReadWritePaths = [remoteOsCheckout "/home/${deployUser}/.ssh" flakeDeployTriggerDir];
    };
    path = ["/run/wrappers" deployFlakeInput] ++ (with pkgs; [nix git git-lfs openssh bash coreutils]);
  };

  # Path watcher: starts flake-deploy.service whenever the trigger file is touched.
  systemd.paths.flake-deploy = {
    wantedBy = ["multi-user.target"];
    pathConfig = {
      PathChanged = flakeDeployTrigger;
      Unit = "flake-deploy.service";
    };
  };

  # Runs `colmena apply-local` as root, detached from the agent. Activation can
  # restart the agent freely; this unit completes on its own.
  systemd.services.flake-deploy = {
    description = "Apply latest remote-os flake.lock via colmena";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      WorkingDirectory = "${remoteOsCheckout}/config";
    };
    path = with pkgs; [nix git];
    script = ''
      nix --accept-flake-config run .#apps.x86_64-linux.colmena -- apply-local
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${remoteOsCheckout} 0755 ${deployUser} users - -"
    "d /home/${deployUser}/.ssh 0700 ${deployUser} users - -"
    "d ${flakeDeployTriggerDir} 0775 ${deployUser} users - -"
    "f ${flakeDeployTrigger} 0664 ${deployUser} users - -"
  ];

  environment.systemPackages = [deployFlakeInput];

  services.caddy.virtualHosts."ci.ony.world".extraConfig = ''
    reverse_proxy http://127.0.0.1:${toString serverPort}
  '';
}
