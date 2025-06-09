{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.root = {
    programs.direnv = {
      enable = true;
      config.global.load_dotenv = true;
    };
    home.stateVersion = "24.11";
  };
}
