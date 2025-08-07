{inputs, ...}: {
  imports = [
    inputs.agenix.nixosModules.default

    ./programs
    ./services
  ];

  virtualisation.docker.enable = true;
}
