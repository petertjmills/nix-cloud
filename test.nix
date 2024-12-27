let
  pkgs = import <nixpkgs> { };
  result =
    let
      mkOption = pkgs.lib.mkOption;
      lib = pkgs.lib;
      modulesPath = ./isos;
    in
    pkgs.lib.evalModules {
      # inherit pkgs modulesPath;
      modules = [
        { _module.args = { inherit pkgs modulesPath; }; }
        ./host-options.nix
        ./hosts.nix
      ];
    };
in
# pkgs.lib.recursiveUpdate result.config.hosts.default result.config.hosts.cumulus
{
  terranix = pkgs.lib.recursiveUpdate result.config.hosts.default.terranix result.config.hosts.cumulus.terranix;

  disko = pkgs.lib.recursiveUpdate result.config.hosts.default.disko result.config.hosts.cumulus.disko;

  modules = result.config.hosts.default.modules ++ result.config.hosts.cumulus.modules;

  system = if result.config.hosts.cumulus.system == "" then result.config.hosts.default.system else result.config.hosts.cumulus.system;

  os = if result.config.hosts.cumulus.os == "" then result.config.hosts.default.os else result.config.hosts.cumulus.os;
}
