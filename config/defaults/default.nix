{inputs, ...}: {
  imports = [
    inputs.agenix.nixosModules.default

    ./programs
    ./services
  ];
}
