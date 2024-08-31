{
  description = "My nix cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, vscode-server, disko, ... }@inputs: {
    nixosConfigurations = {
      cumulus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vscode-server.nixosModules.default
          ./hosts/cumulus/configuration.nix
        ];
      };

      nimbus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./hosts/nimbus/configuration.nix
        ];
      };

      altostratus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./hosts/altostratus/configuration.nix
        ];
      };

      altocumulus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./hosts/altocumulus/configuration.nix
        ];
      };

      cirrustratus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./hosts/cirrustratus/configuration.nix
        ];
      };

      x86_64-linux-iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./isos/x86_64-linux-minimal-cd.nix
        ];
      };
    };

  };
}
