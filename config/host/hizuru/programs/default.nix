{pkgs, ...}: {
  programs = {
    git = {
      enable = true;
      config = {
        user = {
          name = "Hizuru";
          email = "hizuru@ony.world";
        };
      };
    };

    starship.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      go
    ];
  };
}
