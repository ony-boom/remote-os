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
      IMPORT_LOG = "/var/lib/beets/import.log";
    };
    serviceConfig = {
      User = "ony";
      Group = "users";
      ExecStart = "${pkgs.python3}/bin/python3 ${./music-import/server.py}";
      Restart = "on-failure";

      # Only needs to write the staging dir and import-pending.
      ProtectSystem = "strict";
      ReadWritePaths = ["/var/lib/slskd"];
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
      RestrictNamespaces = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      SystemCallArchitectures = "native";
    };
  };
}
