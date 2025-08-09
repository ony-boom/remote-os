{lib, config, ...}: {
  services.tailscale = {
    enable = true;
  };
} // lib.mkIf (config.services.tailscale.enable) {
  networking = {
    nameservers = ["100.100.100.100" "8.8.8.8" "1.1.1.1"];
    search = ["tempel-goblin.ts.net"];
  };
}
