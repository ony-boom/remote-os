{config, ...}: {
  age.secrets.copyparty.file = ../secrets/copyparty.age;

  services.copyparty = {
    enable = true;

    user = "root";

    settings = {
      i = "127.0.0.1";
      p = [3923];
      no-reload = true;
    };

    globalExtraConfig = ''
      rproxy: 1
      xff-hdr: x-forwarded-for
      xff-src: 127.0.0.1
    '';

    accounts = {
      ony.passwordFile = config.age.secrets.copyparty.path;
    };

    volumes = {
      "/music" = {
        path = "/media/music";
        access = {
          r = "ony";
          rw = ["ony"];
        };
      };

      "/videos" = {
        path = "/media/videos";
        access = {
          r = "*";
          rw = ["ony"];
        };
      };

      "/pictures" = {
        path = "/media/pictures";
        access = {
          r = "*";
          rw = ["ony"];
        };
      };
    };
  };
}
