{
  nixpkgs,
  self,
  terranix-storage,
}:
let
  filteredVms = nixpkgs.lib.filterAttrs (
    name: config: config._module.specialArgs.terranix != null
  ) self.nixosConfigurations;

  vmTerraformConfigs = builtins.map (name: filteredVms.${name}._module.specialArgs.terranix) (
    builtins.attrNames filteredVms
  );
  mergedConfigs =
    builtins.foldl'
      (acc: vmConfig: {
        import = acc.import ++ vmConfig.import;
        resource = (nixpkgs.lib.recursiveUpdate acc.resource vmConfig.resource);
      })
      {
        import = [ ];
        resource = { };
      }
      vmTerraformConfigs;

in
nixpkgs.lib.recursiveUpdate mergedConfigs terranix-storage
