{
  config,
  ...
}: {
  age.secrets.umami.file = ../secrets/umami.age;
  services.umami = {
    enable = true;

    settings = {
      APP_SECRET_FILE = config.age.secrets.umami.path;
    };
  };
}
