# Tailscale Services, reached at https://<name>.tempel-goblin.ts.net. Hosting
# them needs hizuru tagged and each Service defined in the admin console
# (tailscale.com/kb/1552).
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Name => local HTTP port.
  services = {
    navidrome = config.services.navidrome.settings.Port;
    filebrowser = config.services.filebrowser.settings.port;
    slskd = config.services.slskd.settings.web.port;
  };
in {
  services.tailscale = {
    enable = true;
    # Enables IP forwarding, for offering an exit node.
    useRoutingFeatures = "server";
  };

  networking = {
    nameservers = ["100.100.100.100" "8.8.8.8" "1.1.1.1"];
    search = ["tempel-goblin.ts.net"];
  };

  # Not services.tailscale.serve: its set-config can't do HTTPS in front of an
  # HTTP backend until a release has tailscale/tailscale#21789.
  systemd.services.tailscale-serve = {
    description = "Tailscale Services";
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
    wantedBy = ["multi-user.target"];
    path = [config.services.tailscale.package pkgs.gnugrep];
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

      # Start from empty so this list stays the source of truth.
      tailscale serve reset

      # One Service missing from the admin console shouldn't take down the rest.
      failed=0
      ${lib.concatLines (lib.mapAttrsToList (name: port: "tailscale serve --service=svc:${name} --https=443 --bg --yes http://127.0.0.1:${toString port} || failed=1") services)}
      exit $failed
    '';
  };
}
