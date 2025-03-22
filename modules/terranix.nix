{ config, lib, ... }:

with lib;

let

  # Create a custom option type for device lists that knows how to merge them
  deviceListType = types.mkOptionType {
    name = "deviceList";
    description = "List of device configurations";
    merge =
      loc: defs:
      let
        # Combine all device lists from all modules
        allDevices = concatLists (map (def: def.value) defs);
      in
      allDevices;
    check = x: builtins.isList x;
    getSubOptions = prefix: { };
    getSubModules = [ ];
    substSubModules = m: deviceListType;
  };

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
    # Main resource definitions
    resource = mkOption {
      type = types.attrsOf (
        types.attrsOf (
          types.submodule {
            freeformType =
              with types;
              let
                validSettingsPrimitiveTypes = oneOf [
                  int
                  str
                  bool
                  float
                  attrs
                ];
                validSettingsTypes = oneOf [
                  validSettingsPrimitiveTypes
                  (listOf validSettingsPrimitiveTypes)
                ];
                settingsType = oneOf [
                  str
                  (attrsOf validSettingsTypes)
                ];
              in
              oneOf [
                settingsType
                (listOf settingsType)
              ]
              // {
                description = ''
                  Terranix resource configuration
                  This is a freeform configuration that will be passed to the Terranix resource
                  module. The structure of this configuration is defined by the resource module
                  itself, and can be found in the module documentation.
                '';
              };
            # options = {
            #   device = mkOption {
            #     type = deviceListType;
            #     default = [ ];
            #     description = "Device configurations";
            #   };
            #   # All other attributes will be merged automatically
            # };
          }
        )

      );
      default = { };
      description = "Terranix resource configuration";
    };

    # Other common Terraform sections that might be needed
    # data = mergeAttrs [ "data" ];
    # provider = mergeAttrs [ "provider" ];
    # module = mergeAttrs [ "module" ];
    # output = mergeAttrs [ "output" ];
    # variable = mergeAttrs [ "variable" ];
    # locals = mergeAttrs [ "locals" ];
    # terraform = mergeAttrs [ "terraform" ];
  };

  config = {
    # No implementation needed here as this is just defining the structure
    # that will be consumed externally
  };
}
