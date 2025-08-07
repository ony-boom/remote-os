{config, ...}: {
  services.umami = {
    enable = true;

    settings = {
      APP_SECRET_FILE = config.age.secrets.umami.path;
    };
  };
}
