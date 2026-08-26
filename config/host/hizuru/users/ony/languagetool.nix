# LanguageTool's OSS server has no auth of its own, so Caddy's basic_auth gates
# it; LT_BASIC_USER/LT_BASIC_HASH/LT_PATH_TOKEN come from the caddy.age secret
# (see ./caddy.nix).
{config, ...}: {
  services.languagetool = {
    enable = true;
    allowOrigin = "*";

    settings = {
      trustXForwardForHeader = true;
      requestLimit = 300;
      requestLimitPeriodInSeconds = 60;
      maxTextLength = 40000;
      maxCheckTimeMillis = 30000;
    };

    jvmOptions = ["-Xmx512m"];
  };

  # Two mutually exclusive handlers. Order matters: at the top level basic_auth
  # is evaluated before handle, so it would gate the token path too.
  services.caddy.virtualHosts."lt.ony.world".extraConfig = ''
    # The browser extension can't send basic auth (no field for it), so it gets
    # a secret path prefix instead - same idea as a bearer token, in the URL.
    handle_path /{$LT_PATH_TOKEN}/* {
      reverse_proxy http://127.0.0.1:${toString config.services.languagetool.port}
    }

    handle {
      basic_auth {
        {$LT_BASIC_USER} {$LT_BASIC_HASH}
      }

      reverse_proxy http://127.0.0.1:${toString config.services.languagetool.port}
    }
  '';
}
