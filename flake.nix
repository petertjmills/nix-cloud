{
  description = "My nix cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
  };

  outputs = { self, nixpkgs, vscode-server, disko, agenix, ... }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
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
            agenix.nixosModules.default
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

      };

      packages.x86_64-linux =
        # let
        #   age.secrets.iphone_wireguard_private_key.file = ./secrets/iphone_wireguard_private_key.age;
        #   agenixv = agenix.nixosModules.default;
        #   test = agenixv {

        #   };
        #   test = builtins.trace ''${config}'' '' test123'';
        #   # privateKeyFile = config.age.secrets.iphone_wireguard_private_key.path;
        # in
        {
          createiPhoneWireguardQrCode = pkgs.writeScriptBin "createiPhoneWireguardQrCode" ''
            cd ${self + /secrets}
            ${agenix.packages.x86_64-linux.default + /bin/agenix} -d iphone_wireguard_private_key.age | ${pkgs.qrencode + /bin/qrencode} -t ansiutf8
          '';
        };

    };
}
