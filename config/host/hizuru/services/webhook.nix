{config, ...}: {
  age.secrets.webhook-env = {
    file = ../secrets/webhook-env.age;
    owner = "ony";
    group = "users";
  };

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
                "secret": "{{ getenv "GH_SECRET" | js }}",
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

  systemd.services.webhook.serviceConfig = {
    EnvironmentFile = config.age.secrets.webhook-env.path;
  };
}
