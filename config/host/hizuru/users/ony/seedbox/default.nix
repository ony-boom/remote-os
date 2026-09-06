# Seedbox: download on hizuru's uplink, fetch over HTTPS later.
#
# Everything lands on a 50G ext4 loop image mounted at /srv/seedbox. The root LV
# already claims 100%FREE (../../../disk-config.nix), so there are no free extents
# for a new LV and ext4 can't shrink online; an image file is the only cap that
# holds by construction on a box we can only reach over SSH.
{pkgs, ...}: let
  img = "/var/lib/seedbox.img";
  root = "/srv/seedbox";
in {
  imports = [
    ./qbittorrent.nix
    ./aria2.nix
    ./jdownloader.nix
  ];

  # gid is pinned because JDownloader's container takes it as a literal GROUP_ID;
  # an auto-allocated gid is null at eval time and can't be interpolated.
  users.groups.seedbox.gid = 4000;
  users.users.ony.extraGroups = ["seedbox"];

  boot.kernelModules = ["loop"];

  systemd.services.seedbox-image = {
    description = "Create the 50G seedbox filesystem image";
    unitConfig.ConditionPathExists = "!${img}";
    requiredBy = ["srv-seedbox.mount"];
    before = ["srv-seedbox.mount"];
    path = [pkgs.coreutils pkgs.e2fsprogs pkgs.util-linux];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # fallocate, not truncate: the 50G is reserved for real, so the cap holds in
    # both directions. tmp + rename: a crash mid-mkfs leaves no ${img}, so the
    # ConditionPathExists above can't latch a half-made image forever.
    script = ''
      rm -f ${img}.tmp
      fallocate -l 50G ${img}.tmp
      mkfs.ext4 -F -m 0 -L seedbox ${img}.tmp
      mv ${img}.tmp ${img}
    '';
  };

  # systemd.mounts, not fileSystems: fileSystems writes /etc/fstab, which makes
  # local-fs.target Requires= this mount, and local-fs.target carries
  # OnFailure=emergency.target. A bad image would make a headless VPS unreachable.
  systemd.mounts = [
    {
      what = img;
      where = root;
      type = "ext4";
      options = "loop,noatime,nodev,nosuid,noexec";
      # mountToUnit supplies no default; without this the unit exists but never
      # starts.
      wantedBy = ["multi-user.target"];
    }
  ];

  # NOT systemd.tmpfiles.rules: systemd-tmpfiles-setup is After=local-fs.target,
  # so it runs before this mount and would create the tree on the root fs, which
  # the mount then hides - everything would write to / uncapped.
  #
  # http/ is here too even though the aria2 module has its own tmpfiles rule for
  # it, for exactly that reason: that rule fires pre-mount and gets shadowed, and
  # aria2 cannot mkdir it itself under a root-owned 0755 parent. Ownership is
  # kept identical to the module rule so a later tmpfiles run is a no-op.
  systemd.services.seedbox-dirs = {
    description = "Create seedbox subdirectories on the mounted image";
    requires = ["srv-seedbox.mount"];
    after = ["srv-seedbox.mount"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.coreutils];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      install -d -o ony -g seedbox -m 2775 \
        ${root}/torrents ${root}/torrents/incomplete \
        ${root}/torrents/complete ${root}/hosters
      install -d -o aria2 -g aria2 -m 2775 ${root}/http
      chmod 0755 ${root}
    '';
  };

  # The tree is 0755 with 0644/0664 files so caddy reads it as itself; the
  # seedbox group is for write access, so caddy stays out of it.
  # SEEDBOX_BASIC_USER/SEEDBOX_BASIC_HASH come from caddy.age (see ../caddy.nix).
  services.caddy.virtualHosts."dl.ony.world".extraConfig = ''
    basic_auth {
      {$SEEDBOX_BASIC_USER} {$SEEDBOX_BASIC_HASH}
    }

    root * ${root}

    # No `encode` here, unlike the other vhosts: on multi-GB already-compressed
    # media it's pure CPU burn and it gets in the way of byte-range serving.
    # file_server goes through http.ServeContent, so Accept-Ranges works and
    # downloads are resumable.
    file_server browse {
      hide *.!qB
    }
  '';
}
