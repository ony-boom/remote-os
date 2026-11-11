# Files whatever slskd finishes downloading into /media/music, laid out like
# the deemix-era library: Artist/Album/Artist - Title, with an .lrc beside it.
{pkgs, ...}: let
  py = pkgs.python3.pkgs;
  beets = py.toPythonApplication (py.beets.override {
    disableAllPlugins = true;
    pluginOverrides = {
      lyrics.enable = true;
      musicbrainz.enable = true;
    };
    doCheck = false;
  });

  config = (pkgs.formats.yaml {}).generate "beets.yaml" {
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

  beet = "${beets}/bin/beet -c ${config}";
  downloads = "/var/lib/slskd/downloads";
in {
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
      ${beet} import ${downloads}

      # Navidrome reads lyrics from sidecars, like the rest of the library.
      ${beet} ls -f '$path' 'lyrics::.' | while IFS= read -r track; do
        lrc="''${track%.*}.lrc"
        [ -e "$lrc" ] || ${beet} ls -f '$lyrics' "path:$track" > "$lrc"
      done
    '';
  };
}
