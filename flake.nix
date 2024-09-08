{
  description = "My nix cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
  };

  outputs = { self, nixpkgs, vscode-server, disko, agenix, ... }@inputs: {
    nixosConfigurations = {
      cumulus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vscode-server.nixosModules.default
          ./hosts/cumulus/configuration.nix
          agenix.nixosModules.default
          {
            environment.systemPackages = [ agenix.packages.x86_64-linux.default ];
          }
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

      cirrus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          agenix.nixosModules.default
          ./hosts/cirrus/configuration.nix
        ];
      };

      stratus = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          disko.nixosModules.disko
          agenix.nixosModules.default
          ./hosts/stratus/configuration.nix
        ];
      };

      x86_64-linux-iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./isos/x86_64-linux-minimal-cd.nix
        ];
      };

      packages.x86_64-linux = {
        createQrCode = nixpkgs.legacyPackages.x86_64-linux.writeScriptBin "test" ''
          echo "Hello, world!"
        '';
      };
    };

  };
}
