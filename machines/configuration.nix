{
  imports = [
    ./programs
  ];
  users.users = let
    publicKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFk4ydn78plOeWDhjNZbQSJbKr6mLciXme4XmYmzYnXy onyrakoto27@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKdRN6F9/e84/Jvl3oqTE0UVJ14zVemp3X/814zR1TON orakotonirina@bocasay.com"
    ];
  in {
    root = {
      openssh.authorizedKeys.keys = publicKeys;
    };
    ony = {
      isNormalUser = true;
      home = "/home/ony";
      extraGroups = ["wheel" "networkmanager"];
      openssh.authorizedKeys.keys = publicKeys;
    };
  };

  networking = {
    firewall = {
      allowedTCPPorts = [22];
    };
  };

  system.stateVersion = "24.05";
}
