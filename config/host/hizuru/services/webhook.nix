{config, ...}: {
  age.secrets.gh-hooks.file = ../secrets/gh-hooks.age;

  services.webhook = {
    enable = true;
    port = 9000;
    user = "ony";
    group = "users";
    ip = "127.0.0.1";

    enableTemplates = true;

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
                    "secret": "{{ readFile \"${config.age.secrets.gh-hooks.path}\" }}",
                    "parameter": {
                      "source": "header",
                      "name": "X-Hub-Signature"
                    }
                  }
                },
                {
                  "match": {
                    "type": "value",
                    "value": "refs/heads/master",
                    "parameter": {
                      "source": "payload",
                      "name": "ref"
                    }
                  }
                }
              ]
            }
          }
        '';
    };
  };
}
