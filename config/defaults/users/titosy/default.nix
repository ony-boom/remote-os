{pkgs, ...}: {
  users.users.titosy = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
    shell = pkgs.zsh;
    hashedPassword = "$6$rlEnH.9.J8fi1Kw2$o1MRrZoQxrQmRf2u2bXXLYLeygY815stnZY7zbsTTexQQmgJFwfM5SuP0LACWL0sj.T./JtAoSVdPRSOATXSS0";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfA9T74URZ3QKWGC1guq6+WJmhCqRh0LXQ1HeFJ6O4f dev.titosy@gmail.com"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6SVOMh8b6tVka9PB0QKInfH73/vbl5cxQKUQ6yLifwBqlx27jBbEC0uiHRIpJNlN+kTd613QkWIRbF/tsUtORWa/jI/X+nWD752cQbI0zcSLA/vhabQVJduiJkdPX4FtigN8L2MNabVLL0K+NFodT3R3/h+94jkn7z+zZeN+dB6ctmcowhJeSMWn3l9IexJflgxmin7MtfRHhxq2uBUKgeMc6W/K6HshVmDu/ATo25MpJJ3yy2TghJb6gZxsAzLwxEaeD25Wh8mqmMP0D9cHECztPOOmxZnLo5g57CKmar0Fp1ACSNstGQcEr5HkGAxZJggN64lBI1sk65n6tUFEyFU5ruUzW8I6U4oE6ciaL1jkV1Bpv3lUGhJDH7kKM4PlO4I0il6nTR3Gzu5TlJ5rj2Ig6ZNZ1xGnmOfpAnaj6GKbEevGDHUc1qTwv6GZnlDPrFW5jx/ZMK+7PToyVtHc4JlmVCPoMJSrerbYj6rOMHnrFkVZ9RUCGbysNaOUD58j2h3BnQNNCrFzmW+kcuc42ZEB4zknO0c7TrMNCEmGbWeZR97hBnDyiy7CEyyVxoB9icM8N92XCW7gS3IiIE7iMYoAWKjJ3ugsOheX22JEaLuSX0nhRhttU+SVfgKHDI0lMgEjqtv8bLm/SitnrqXzjNxdSC8/tlVIJWA7CRatoOw== dokploy"
    ];
  };

  nix.settings.trusted-users = ["titosy"];

  # Passwordless sudo so `colmena apply` can run the activation script as root.
  security.sudo.extraRules = [
    {
      users = ["titosy"];
      commands = [{command = "ALL"; options = ["NOPASSWD"];}];
    }
  ];

  home-manager.users.titosy = import ./home.nix;
}
