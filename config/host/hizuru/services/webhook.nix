{config, ...}: {
  age.secrets.webhook-env.file = ../secrets/webhook-env.age;

  services.webhook = {
    enable = true;
    port = 9000;
    user = "ony";
    group = "users";
    ip = "127.0.0.1";
    hooksTemplated = {
      redeploy =
        /*
        json
        */
        ''
          {
            "id": "redeploy-webhook",
            "execute-command": "make update-local",
            "command-working-directory": "/srv/os-config",
            "trigger-rule": {
              "match": {
                "type": "payload-hmac-sha256",
                "secret": "{{ .Env.GH_SECRET }}",
                "parameter": {
                  "source": "header",
                  "name": "X-Hub-Signature-256"
                }
              }
            }
          }
        '';
    };
  };

  # Override the systemd service to load the secret as an environment variable
  systemd.services.webhook = {
    serviceConfig = {
      EnvironmentFile = config.age.secrets.webhook-env.path;
    };
  };
}
