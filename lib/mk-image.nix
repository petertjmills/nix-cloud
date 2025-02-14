{ nixpkgs }:
{ name, module }:
rec {
  inherit name;
  nixosConfig = nixpkgs.lib.nixosSystem {
    modules = [
      module
    ];
  };
  build = nixosConfig.config.system.build;
}
