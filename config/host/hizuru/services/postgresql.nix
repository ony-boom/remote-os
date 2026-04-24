{
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    authentication = ''
      host all all 100.64.0.0/10 scram-sha-256
      host all all 172.17.0.0/16 scram-sha-256
    '';
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [5432];
  networking.firewall.interfaces.docker0.allowedTCPPorts = [5432];
}
