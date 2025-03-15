{ config, lib, ... }:

with lib;

let
  cfg = config.terranix;

  # Helper function to merge attributes recursively
  mergeAttrs = attrPath: mkOption {
    type = types.attrsOf types.anything;
    default = {};
    description = "Terranix ${toString attrPath} configuration";
  };

in {
  options.terranix = {
    # Main resource definitions
    resource = mergeAttrs ["resource"];

    # Other common Terraform sections that might be needed
    data = mergeAttrs ["data"];
    provider = mergeAttrs ["provider"];
    module = mergeAttrs ["module"];
    output = mergeAttrs ["output"];
    variable = mergeAttrs ["variable"];
    locals = mergeAttrs ["locals"];
    terraform = mergeAttrs ["terraform"];
  };

  config = {
    # No implementation needed here as this is just defining the structure
    # that will be consumed externally
  };
}
