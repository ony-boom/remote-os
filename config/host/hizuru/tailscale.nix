# Published with services.tailscale.serve.services, reached at
# https://<name>.tempel-goblin.ts.net. Endpoints use tls-terminated-tcp because
# an http:// target would serve plain HTTP on the inbound port.
#
# Hosting a Service needs hizuru tagged, and each Service defined in the admin
# console (tailscale.com/kb/1552).
{
  config,
  pkgs,
  ...
}: {
  services.tailscale = {
    enable = true;
    # Enables IP forwarding, for offering an exit node.
    useRoutingFeatures = "server";
    serve.enable = true;
  };

  networking = {
    nameservers = ["100.100.100.100" "8.8.8.8" "1.1.1.1"];
    search = ["tempel-goblin.ts.net"];
  };

  systemd.services.tailscale-serve = {
    path = [config.services.tailscale.package pkgs.gnugrep];
    preStart = ''
      # tailscaled being active is not the same as the node being up; serve
      # fails while the backend is still starting or logged out.
      for _ in $(seq 60); do
        if tailscale status --json 2>/dev/null \
          | grep -q '"BackendState":[[:space:]]*"Running"'; then
          break
        fi
        sleep 2
      done

      # set-config only replaces Services, so this is what clears any
      # imperative node-level mappings and keeps this config the source of truth.
      tailscale serve reset
    '';
  };
}
