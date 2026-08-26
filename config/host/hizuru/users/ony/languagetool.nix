# LanguageTool's OSS server has no auth of its own, so Caddy's basic_auth gates
# it; LT_BASIC_USER/LT_BASIC_HASH come from the caddy.age secret (see ./caddy.nix).
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

  services.caddy.virtualHosts."lt.ony.world".extraConfig = ''
    basic_auth {
      {$LT_BASIC_USER} {$LT_BASIC_HASH}
    }

    reverse_proxy http://127.0.0.1:${toString config.services.languagetool.port}
  '';
}
