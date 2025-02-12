{ nixpkgs }:
{ name, module }:
rec {
  inherit name;
  nixosConfig = nixpkgs.lib.nixosSystem {
    modules = [
      module
    ];
  };
  img = nixosConfig.config.system.build.squashfs;
  metadata = nixosConfig.config.system.build.metadata;
}
