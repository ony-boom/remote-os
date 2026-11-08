{config, ...}: {
  age.secrets.navidrome.file = ./secrets/navidrome.age;

  services = {
    navidrome = {
      environmentFile = config.age.secrets.navidrome.path;
      enable = true;
      user = "ony";
      settings = {
        MusicFolder = "/media/music";
        # The 100MB default evicts covers, which then get regenerated on demand.
        ImageCacheSize = "2GB";
      };
    };

    # Public, so navidrome's login is the only guard. Leave ExtAuth.TrustedSources
    # unset: it also trusts Remote-User from 127.0.0.1, where tailscale serve
    # connects from too, which would allow logging in without a password.
    caddy.virtualHosts."music.ony.world".extraConfig = ''
      # Content-hashed filenames, and navidrome sends no cache headers for them.
      header /app/assets/* Cache-Control "public, max-age=31536000, immutable"
      reverse_proxy 127.0.0.1:4533
    '';

    tailscale.serve.services.navidrome.endpoints."tcp:443" = "tls-terminated-tcp://127.0.0.1:4533";
  };
}
