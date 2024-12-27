{ pkgs, hostconfig, ... }:
let
  hostsDefault = hostconfig.default;
  hosts = builtins.mapAttrs
    (name: value:
      {
        terranix = pkgs.lib.recursiveUpdate hostsDefault.terranix value.terranix;

        disko = pkgs.lib.recursiveUpdate hostsDefault.disko value.disko;

        modules = hostsDefault.modules ++ value.modules;

        system = if value.system == "" then hostsDefault.system else value.system;

        os = if value.os == "" then hostsDefault.os else value.os;
      }
    )
    (builtins.removeAttrs hostconfig [ "default" ]);
in
hosts
