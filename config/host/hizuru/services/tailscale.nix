# `tailscale serve` is imperative: the mapping lives in tailscaled's own state,
# not in this repo, so a published port survives being deleted from the config
# and there is no record of why it exists.
#
# services.tailscaleServe below is the single source of truth instead. The
# reconciler resets the whole serve config and replays the declared set, so
# adding an entry serves it and removing one unserves it on the next deploy.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatLines mapAttrsToList mkIf mkOption types;
  cfg = config.services.tailscaleServe;
in {
  options.services.tailscaleServe = mkOption {
    description = ''
      Local ports to publish over the tailnet, keyed by the port they are reached
      on at `https://<magicdns-name>:<port>`.

      Every mapping that should exist has to be declared here. The reconciler
      resets the node's serve config before replaying this set, so anything left
      out is removed - that is what makes deletion work.
    '';
    default = {};
    example = {
      "8090".target = "http://localhost:8090";
    };
    type = types.attrsOf (types.submodule {
      options = {
        target = mkOption {
          type = types.str;
          example = "http://localhost:8090";
          description = "What tailscaled proxies the port to.";
        };

        funnel = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Publish to the public internet rather than the tailnet only. This
            takes the service out from behind tailscale's device authentication,
            so whatever is behind it has to stand on its own.
          '';
        };
      };
    });
  };

  config = {
    services.tailscale.enable = true;

    networking = {
      nameservers = ["100.100.100.100" "8.8.8.8" "1.1.1.1"];
      search = ["tempel-goblin.ts.net"];
    };

    # The script text changes only when the set above does, so
    # switch-to-configuration restarts this then and not on unrelated deploys -
    # the brief window where nothing is served stays rare.
    systemd.services.tailscale-serve = mkIf (cfg != {}) {
      description = "Reconcile tailscale serve with the declared mappings";
      after = ["tailscaled.service"];
      requires = ["tailscaled.service"];
      wantedBy = ["multi-user.target"];
      path = [config.services.tailscale.package pkgs.coreutils pkgs.gnugrep];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # tailscaled being active is not the same as the node being up; serve
        # fails while the backend is still starting or logged out.
        for _ in $(seq 60); do
          if tailscale status --json 2>/dev/null \
            | grep -q '"BackendState":[[:space:]]*"Running"'; then
            break
          fi
          sleep 2
        done

        # Drops everything, funnel included. Every mapping is replayed below, so
        # an entry deleted from the nix config disappears here.
        tailscale serve reset

        ${concatLines (mapAttrsToList (
            port: c: let
              cmd =
                if c.funnel
                then "tailscale funnel"
                else "tailscale serve";
            in "${cmd} --bg --yes --https=${port} ${lib.escapeShellArg c.target}"
          )
          cfg)}
      '';
    };
  };
}
