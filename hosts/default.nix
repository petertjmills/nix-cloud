{
  nixpkgs ? <nixpkgs>,
  ipPool,
  inputs,
  self,
  ...
}:

let
  # returns attrset of `file` -> `file type (dir|file)`
  files = builtins.readDir ./.;

  # filter out default.nix
  # filter out files that don't end in .nix
  hostFiles = builtins.filter (name: name != "default.nix" && nixpkgs.lib.hasSuffix ".nix" name) (
    builtins.attrNames files
  );

  # Remove the .nix extension to get the host name
  hostNames = map (file: builtins.substring 0 (builtins.stringLength file - 4) file) hostFiles;

  # Create a nixosSystem for each host
  mkHost = hostName: {
    name = hostName;
    specialArgs = {
      inherit ipPool self inputs;
    };
    value = nixpkgs.lib.nixosSystem {
      modules = [
        (./. + "/${hostName}.nix")
        inputs.disko.nixosModules.default
        { _module.args = { inherit inputs; }; }
        {
          system.stateVersion = "24.05";
        }
      ];
    };
  };

  # Convert the list of host names to an attribute set of nixosSystem configurations
  hosts = builtins.listToAttrs (map mkHost hostNames);
in
hosts
