{
  description = "My nix cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, vscode-server, disko, ... }@inputs: {
    nixosConfigurations.cumulus = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        vscode-server.nixosModules.default
        ./cumulus/configuration.nix
      ];
    };

    nixosConfigurations.nimbus = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./nimbus/configuration.nix
      ];
    };

    nixosConfigurations.altostratus = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./altostratus/configuration.nix
      ];
    };

  };
}
