{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ../default.nix # Shared
  ];
}
