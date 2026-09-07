{
  services.filebrowser = {
    enable = true;
    user = "ony";
    settings = {
      root = "/home/ony";
    };
  };

  services.tailscaleServe."8080".target = "http://localhost:8080";
}
