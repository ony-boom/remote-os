{
  services = {
    filebrowser = {
      enable = true;
      user = "ony";
      settings.root = "/home/ony";
    };

    tailscale.serve.services.filebrowser.endpoints."tcp:443" = "tls-terminated-tcp://127.0.0.1:8080";
  };
}
