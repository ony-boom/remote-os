# File hosters (Mega, 1fichier, ...). The weakest leg of the seedbox: a JVM under
# a noVNC/X session in a ~1G image. Try aria2 with a pasted Cookie/Referer header
# first - it covers a fair number of hoster links on its own.
{config, ...}: let
  webPort = 5800;
in {
  age.secrets.jdownloader.file = ../secrets/jdownloader.age;

  virtualisation.oci-containers.containers.seedbox-jdownloader = {
    image = "jlesage/jdownloader-2:v26.08.2@sha256:f16d47986bf6a5db6d67484e3b7e76404bce74f6f212809127a79eb76aa1c641";

    ports = ["127.0.0.1:${toString webPort}:5800"];

    volumes = [
      "/srv/seedbox/hosters:/output"
      "/var/lib/jdownloader:/config"
    ];

    environment = {
      # Only GROUP_ID is load-bearing: /srv/seedbox/hosters is 2775 root:seedbox
      # with setgid, so any uid in group 4000 can write and new files inherit the
      # group. USER_ID just keeps the files off root.
      USER_ID = "1000";
      GROUP_ID = "4000";

      # LanguageTool already holds -Xmx3g of the box's 12G; cap this JVM so the
      # two can't collide.
      JDOWNLOADER_MAX_MEM = "1G";

      WEB_AUTHENTICATION = "1";
      # caddy terminates TLS and proxies over plain http, so the container only
      # ever sees an insecure hop and would otherwise refuse to authenticate.
      WEB_AUTHENTICATION_ALLOW_INSECURE = "1";
    };

    # WEB_AUTHENTICATION_USERNAME / WEB_AUTHENTICATION_PASSWORD.
    environmentFiles = [config.age.secrets.jdownloader.path];
  };

  # Docker bind mounts are rbind,rprivate: a container started before the loop
  # image is mounted stays wired to the pre-mount inode and writes to the root
  # filesystem forever, with no error. This ordering is not optional.
  systemd.services.docker-seedbox-jdownloader = {
    unitConfig.RequiresMountsFor = "/srv/seedbox";
    after = ["seedbox-dirs.service"];
    requires = ["seedbox-dirs.service"];
  };

  # Deliberately no basic_auth, unlike the other seedbox vhosts. noVNC talks over
  # a WebSocket, and browsers don't reliably attach cached basic-auth credentials
  # to a WS handshake - the gate would 401 the console while looking like it
  # worked. The container's own WEB_AUTHENTICATION above is the real boundary.
  services.caddy.virtualHosts."jd.ony.world".extraConfig = ''
    reverse_proxy http://127.0.0.1:${toString webPort}
  '';
}
