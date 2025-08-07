{
  services.umami = {
    enable = true;

    settings = {
      APP_SECRET_FILE = "/run/secrets/umami-app-secret";
    };
  };
}
