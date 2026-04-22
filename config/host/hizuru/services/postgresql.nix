{
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    authentication = ''
      host all all 100.64.0.0/10 scram-sha-256
    '';
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [5432];
}
