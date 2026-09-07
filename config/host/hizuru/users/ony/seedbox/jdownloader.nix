# File hosters (Mega, 1fichier, ...). The weakest leg of the seedbox: a JVM under
# a noVNC/X session in a ~1G image. Try aria2 with a pasted Cookie/Referer header
# first - it covers a fair number of hoster links on its own.
#
# Reached over the tailnet with `tailscale serve` (see seedbox.md); no caddy
# vhost and no firewall rule, since the container already listens on loopback.
{config, ...}: let
  webPort = 5800;
in {
  age.secrets.jdownloader.file = ../secrets/jdownloader.age;

  virtualisation.oci-containers.containers.seedbox-jdownloader = {
    image = "jlesage/jdownloader-2:v26.08.2@sha256:f16d47986bf6a5db6d67484e3b7e76404bce74f6f212809127a79eb76aa1c641";

    # Published on loopback deliberately. Docker publishes ports with DNAT in
    # nat/PREROUTING plus the FORWARD chain, which never traverses the INPUT
    # chain the NixOS firewall writes - so binding this to 0.0.0.0 and trusting
    # firewall.interfaces.tailscale0 would leave it world-open with no warning.
    ports = ["127.0.0.1:${toString webPort}:5800"];

    volumes = [
      "/srv/seedbox/hosters:/output"
      "/var/lib/jdownloader:/config"
    ];

    environment = {
      # ony is uid 1000 on hizuru. Only GROUP_ID is strictly load-bearing:
      # /srv/seedbox/hosters is 2775 with setgid, so any uid in group 4000 can
      # write and new files inherit the group.
      USER_ID = "1000";
      GROUP_ID = "4000";

      # hizuru has ~5.5G available and LanguageTool already holds -Xmx3g; cap
      # this JVM so the two can't collide.
      JDOWNLOADER_MAX_MEM = "1G";

      WEB_AUTHENTICATION = "1";
      # The tailnet is the real boundary, but the container's own login stays on
      # as a second layer. tailscaled proxies over plain http, so without this it
      # would refuse to authenticate at all.
      WEB_AUTHENTICATION_ALLOW_INSECURE = "1";
    };

    # WEB_AUTHENTICATION_USERNAME / WEB_AUTHENTICATION_PASSWORD.
    environmentFiles = [config.age.secrets.jdownloader.path];
  };

  services.tailscaleServe."${toString webPort}".target = "http://127.0.0.1:${toString webPort}";

  # Docker bind mounts are rbind,rprivate: a container started before the loop
  # image is mounted stays wired to the pre-mount inode and writes to the root
  # filesystem forever, with no error. This ordering is not optional.
  systemd.services.docker-seedbox-jdownloader = {
    unitConfig.RequiresMountsFor = "/srv/seedbox";
    after = ["seedbox-dirs.service"];
    requires = ["seedbox-dirs.service"];
  };
}
