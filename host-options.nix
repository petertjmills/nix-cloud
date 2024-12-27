{ pkgs, lib, ... }:
let
  hostOptions = { ... }: {
    options = {
      terranix = lib.mkOption {
        type = lib.types.nullOr lib.types.attrs;
        default = null;
      };

      disko = lib.mkOption {
        type = lib.types.nullOr lib.types.attrs;
        default = {};
      };

      modules = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf (lib.types.either lib.types.path lib.types.attrs));
        default = [];
      };

      system = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "";
      };

      os = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "";
      };
    };
  };

in
{
  options = {
    hosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule hostOptions);
    };
  };
}
