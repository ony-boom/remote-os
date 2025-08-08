{config, ...}: {
  age.secrets.gh-hooks.file = ../secrets/gh-hooks.age;

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
              "and": [
                {
                  "match": {
                    "type": "payload-hmac-sha1",
                    "secret": "{{ .Env.GH_SECRET }}",
                    "parameter": {
                      "source": "header",
                      "name": "X-Hub-Signature"
                    }
                  }
                }
              ]
            }
          }
        '';
    };
    environment = {
      GH_SECRET = config.age.secrets.gh-hooks.path;
    };
  };
}
