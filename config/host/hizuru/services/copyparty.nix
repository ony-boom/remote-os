{config, ...}: {
  age.secrets.copyparty.file = ../secrets/copyparty.age;

  services.copyparty = {
    enable = true;

    user = "root";

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
    };
  };
}
