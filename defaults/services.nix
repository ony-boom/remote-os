{
  services = {
    caddy.enable = true;
    fail2ban.enable = true;

    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [22 80 443];
    # HTTP/3
    allowedUDPPorts = [443];
  };

  virtualisation = {
    docker.enable = true;
    oci-containers.backend = "docker";
  };
}
