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

    value = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit ipPool self inputs;
      };
      # system = if hostName == "cirrus" then "aarch64-linux" else "x86_64-linux";
      # system = "x86_64-linux";

      modules = [
        (./. + "/${hostName}.nix")
        inputs.disko.nixosModules.default
        # { _module.args = { inherit inputs; }; }
        {
          nix.settings.experimental-features = [
            "nix-command"
            "flakes"
          ];
          services.openssh.enable = true;
          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8tQOhDkrQO4q3W7JdernvtL1v+aiNsjozN41qrfs2n Silversurfer"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyxwQIShLIk/qHVnEkRWC+7/V82brDH3s0tBwpnttVi macmini"
          ];
          users.users.root.openssh.authorizedKeys.keyFiles = [
            ../secrets/public-keys/master_id_ed25519.pub
            ../secrets/public-keys/cumulus_id_ed25519.pub
          ];
          system.stateVersion = "24.05";
        }
      ];
    };
  };

  # Convert the list of host names to an attribute set of nixosSystem configurations
  hosts = builtins.listToAttrs (map mkHost hostNames);
in
hosts
