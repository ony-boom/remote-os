{name, ...}: {
  imports = [
    ./defaults
  ];

  services.openssh.enable = true;

  users.users = let
    publicKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgVuwykGRL/ospBa4ZDuHjd1dQhIFL1xrMctx8BWbMm onyrakoto27@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGyEacEDE0nUT+0fkFDYpZmjwUUVWVDjQVGoNQctdiHe orakotonirina@bocasay.com"
    ];
  in {
    root = {
      openssh.authorizedKeys.keys = publicKeys;
    };
  };

  networking = {
    hostName = name;
    firewall = {
      allowedTCPPorts = [22 80 443];
    };
  };

  system.stateVersion = "25.05";
}
