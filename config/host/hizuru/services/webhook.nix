{config, ...}: let
  hooks = {
    redeploy = {
      id = "redeploy-webhook";
      execute-command = "make update-local";
      command-working-directory = "/srv/os-config";

      trigger-rule = {
        match = {
          type = "payload-hmac-sha1";
          secret = builtins.readFile config.age.secrets.gh-hooks.path;
          parameter = {
            source = "header";
            name = "X-Hub-Signature";
          };
        };
      };
    };
  };
in {
  age.secrets.gh-hooks.file = ../secrets/gh-hooks.age;
  services.webhook = {
    enable = true;
    port = 9000;
    user = "ony";
    ip = "127.0.0.1";

    inherit hooks;
  };
}
