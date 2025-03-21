{ config, lib, ... }:

with lib;

let
  cfg = config.terranix;

  # Custom merge function for handling lists in device attributes
  mergeDeviceLists =
    loc: defs:
    let
      # Combine all device lists from all modules
      allDevices = concatLists (map (def: def.value) defs);
    in
    {
      value = allDevices;
    };

  # Create a recursive type for resources that properly handles nesting and lists
  resourceType = types.attrsOf (
    types.submodule (
      { name, config, ... }:
      {
        options = {
          # Standard attributes with default merging
          name = mkOption {
            type = types.str;
            description = "Resource name";
          };

          image = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Container image";
          };

          # Config is a nested attribute set
          config = mkOption {
            type = types.attrsOf types.anything;
            default = { };
            description = "Resource configuration";
          };

          limits = mkOption {
            type = types.attrsOf types.anything;
            default = { };
            description = "Resource limits";
          };

          # Device is a list that needs special handling for merging
          device = mkOption {
            type = types.listOf (types.attrsOf types.anything);
            default = [ ];
            description = "Resource devices";
            apply = x: x; # Identity function
            # This is the key part - custom merge function for the device list
            merge = mergeDeviceLists;
          };

          # Catch-all for any other properties we haven't explicitly defined
          # This ensures other attributes still get properly merged
          # but without special handling
          _module.freeformType = types.attrsOf types.anything;
        };
      }
    )
  );

  # Helper function to create attribute options
  mergeAttrs =
    attrPath:
    mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Terranix ${toString attrPath} configuration";
    };

in
{
  options.terranix = {
    # Main resource definitions that need special handling for device lists
    resource = mkOption {
      type = types.attrsOf resourceType;
      default = { };
      description = "Terranix resource configuration";
    };

    # Other common Terraform sections that might be needed
    data = mergeAttrs [ "data" ];
    provider = mergeAttrs [ "provider" ];
    module = mergeAttrs [ "module" ];
    output = mergeAttrs [ "output" ];
    variable = mergeAttrs [ "variable" ];
    locals = mergeAttrs [ "locals" ];
    terraform = mergeAttrs [ "terraform" ];
  };

  config = {
    # No implementation needed here as this is just defining the structure
    # that will be consumed externally
  };
}
