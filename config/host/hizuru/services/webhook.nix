let
  hooks = {
    redeploy = {
      id = "redeploy-webhook";
      execute-command = "make update-local";
      command-working-directory = "/srv/os-config";
    };
  };
in {
  services.webhook = {
    enable = true;
    port = 9000;
    user = "ony";
    ip = "127.0.0.1";

    inherit hooks;
  };
}
