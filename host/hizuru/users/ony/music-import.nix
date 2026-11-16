# Drop-zone page for adding songs from the browser, tailnet-only (see
# tailscale.nix). Uploads go where slskd's downloads do, so beets imports them.
{pkgs, ...}: {
  systemd.services.music-import = {
    description = "Upload songs for beets to import";
    wantedBy = ["multi-user.target"];
    path = [pkgs.systemd];
    environment = {
      PORT = "8097";
      PAGE = "${./music-import/index.html}";
      STAGING = "/var/lib/slskd/downloads/web";
      PENDING = "/var/lib/slskd/import-pending";
    };
    serviceConfig = {
      User = "ony";
      Group = "users";
      ExecStart = "${pkgs.python3}/bin/python3 ${./music-import/server.py}";
      Restart = "on-failure";
    };
  };
}
