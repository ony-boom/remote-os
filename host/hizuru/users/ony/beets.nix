# Files whatever slskd finishes downloading into /media/music, laid out like
# the deemix-era library: Artist/Album/Artist - Title, with an .lrc beside it.
{
  lib,
  pkgs,
  ...
}: let
  py = pkgs.python3.pkgs;
  beets = py.toPythonApplication (py.beets.override {
    disableAllPlugins = true;
    pluginOverrides = {
      lyrics.enable = true;
      musicbrainz.enable = true;
    };
    doCheck = false;
  });

  yaml = pkgs.formats.yaml {};

  settings = {
    directory = "/media/music";
    library = "/var/lib/beets/library.db";
    statefile = "/var/lib/beets/state.pickle";
    plugins = ["musicbrainz" "lyrics"];
    # Never prompt; keep the file's own tags when MusicBrainz isn't sure.
    import = {
      move = true;
      quiet = true;
      quiet_fallback = "asis";
      singletons = true;
      log = "/var/lib/beets/import.log";
    };
    paths.singleton = "%first{$albumartist}/$album/%first{$artist,99,0,; ,$, } - $title";
    # Lets emptied download folders be removed.
    clutter = ["*.jpg" "*.jpeg" "*.png" "*.txt" "*.nfo" "*.cue" "*.m3u" "*.m3u8" "*.log" "*.sfv"];
    lyrics = {
      synced = true;
      sources = ["lrclib"];
    };
  };

  config = yaml.generate "beets.yaml" settings;
  beet = "${beets}/bin/beet -c ${config}";

  # A folder matched against MusicBrainz as one album, every track retagged
  # from the release. That keeps albums whole in navidrome.
  albumSettings = lib.recursiveUpdate settings {
    import.singletons = false;
    paths.default = settings.paths.singleton;
  };

  # Unattended: most albums here are partial, so missing tracks don't count
  # against a match. Anything still unsure is left alone.
  autoAlbumConfig = yaml.generate "beets-album-auto.yaml" (lib.recursiveUpdate albumSettings {
    import.quiet_fallback = "skip";
    match = {
      distance_weights.missing_tracks = 0.0;
      max_rec.missing_tracks = "strong";
    };
  });

  # By hand, for what the unattended pass skipped. Args go to `beet import`.
  albumConfig = yaml.generate "beets-album.yaml" (lib.recursiveUpdate albumSettings {
    import.quiet = false;
  });
  retag-album = pkgs.writeShellScriptBin "retag-album" ''
    BEETSDIR=/var/lib/beets exec ${beets}/bin/beet -c ${albumConfig} import -tI "$@"
  '';
  downloads = "/var/lib/slskd/downloads";
in {
  environment.systemPackages = [retag-album];

  # slskd touches this after each finished file.
  systemd.paths.beets-import = {
    wantedBy = ["multi-user.target"];
    pathConfig.PathExists = "/var/lib/slskd/import-pending";
  };

  systemd.services.beets-import = {
    description = "Import slskd downloads into the music library";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    environment.BEETSDIR = "/var/lib/beets";
    serviceConfig = {
      Type = "oneshot";
      User = "ony";
      Group = "users";
      StateDirectory = "beets";
    };
    script = ''
      # Cleared first, so files finishing mid-import trigger another run.
      rm -f /var/lib/slskd/import-pending
      start=$(date +%Y-%m-%dT%H:%M:%S)
      ${beet} import ${downloads}

      # Retag the album folders that just gained tracks.
      ${beet} ls -f '$path' "added:$start.." | sed 's|/[^/]*$||' | sort -u |
        while IFS= read -r album; do
          ${beets}/bin/beet -c ${autoAlbumConfig} import -qI "$album" </dev/null || true
        done

      # Navidrome reads lyrics from sidecars, like the rest of the library.
      ${beet} ls -f '$path' 'lyrics::.' | while IFS= read -r track; do
        lrc="''${track%.*}.lrc"
        [ -e "$lrc" ] || ${beet} ls -f '$lyrics' "path:$track" > "$lrc"
      done
    '';
  };
}
