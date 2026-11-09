{pkgs, ...}: {
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = ["invoiceninja"];
    ensureUsers = [
      {
        name = "invoiceninja";
        ensurePermissions = {
          "invoiceninja.*" = "ALL PRIVILEGES";
        };
      }
    ];
    settings.mysqld = {
      bind-address = "0.0.0.0";
    };
  };

  networking.firewall.interfaces.docker0.allowedTCPPorts = [3306];
}
