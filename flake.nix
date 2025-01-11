{
  description = "My nix cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";

    finance-tracker.url = "git+ssh://git@github.com/petertjmills/finance-tracker-next";

    terranix.url = "github:terranix/terranix";

    musnix.url = "github:musnix/musnix";

    nixvim.url = "github:petertjmills/nixvim";
  };

  outputs =
    {
      self,
      nixpkgs,
      vscode-server,
      disko,
      agenix,
      finance-tracker,
      terranix,
      musnix,
      nixvim,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      unfreePkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      terraformConfiguration = terranix.lib.terranixConfiguration {
        inherit system;
        modules = [ ./config.nix ];
      };
      opentofu-proxmox = pkgs.opentofu.withPlugins (
        ps: with ps; [
          (mkProvider {
            hash = "sha256-dQvJVAxSR0eMeJseDR80MqXX4v7ry794bIr+ilpKBoQ=";
            owner = "Telmate";
            repo = "terraform-provider-proxmox";
            rev = "v3.0.1-rc6";
            vendorHash = "sha256-rD4+m0txQhzw2VmQ56/ZXjtQ9QOufseZGg8TrisgAJo=";
            spdx = "MIT";
            homepage = "https://registry.terraform.io/providers/Telmate/proxmox";
          })
          hcloud
        ]
      );
    in
    {
      nixosConfigurations = {
        cumulus = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs // {
            pkgs = unfreePkgs;
          };
          modules = [
            disko.nixosModules.disko
            vscode-server.nixosModules.default
            ./hosts/cumulus/configuration.nix
            agenix.nixosModules.default
            {
              environment.systemPackages = [
                agenix.packages.x86_64-linux.default
                opentofu-proxmox
                nixvim.packages.x86_64-linux.default

              ];
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
            # ./services/finance-tracker.nix
            finance-tracker.nixosModules.default
            ./hosts/altostratus/configuration.nix
            agenix.nixosModules.default
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

        nixmusic = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            musnix.nixosModules.musnix
            vscode-server.nixosModules.default
            ./hosts/nixmusic/configuration.nix
            {
              services.vscode-server.enable = true;
            }
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
            ${
              agenix.packages.x86_64-linux.default + /bin/agenix
            } -d iphone_wireguard_private_key.age | ${pkgs.qrencode + /bin/qrencode} -t ansiutf8
          '';
        };

      apps.x86_64-linux = {
        # nix run ".#apply"
        apply = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "apply" ''
              if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
              cp ${terraformConfiguration} config.tf.json \
                && ${opentofu-proxmox}/bin/tofu init \
                && ${opentofu-proxmox}/bin/tofu apply
            ''
          );
        };
        # nix run ".#destroy"
        destroy = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "destroy" ''
              if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
              cp ${terraformConfiguration} config.tf.json \
                && ${opentofu-proxmox}/bin/tofu init \
                && ${opentofu-proxmox}/bin/tofu destroy
            ''
          );
        };
      };
    };
}
