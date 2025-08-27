{config, ...}: {
  age.secrets.mms.file = ../secrets/mms.age;
  services.mms = {
    enable = true;
    user = "ony";
    host = "127.0.0.1";
    sessionSecretFile = config.age.secrets.mms.path;
  };
}
