{
  nixpkgs,
  self,
  terranix-storage,
}:
nixpkgs.lib.recursiveUpdate (builtins.foldl'
  (acc: module: nixpkgs.lib.recursiveUpdate acc module.config.terranix)
  { }
  (
    builtins.map
      (name: {
        config.terranix =
          (nixpkgs.lib.filterAttrs (
            name: config: config._module.specialArgs.terranix != null
          ) self.nixosConfigurations).${name}._module.specialArgs.terranix;
      } # Access terranix from specialArgs
      )
      (
        builtins.attrNames (
          nixpkgs.lib.filterAttrs (
            name: config: config._module.specialArgs.terranix != null
          ) self.nixosConfigurations
        )
      )
  )
) terranix-storage
