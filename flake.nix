{
  description = "My nix cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    terranix.url = "github:terranix/terranix";
    terranix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:petertjmills/nixvim";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      terranix,
      disko,
      sops-nix,
      home-manager,
      darwin,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      ...
    }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      # defaultGateway = "192.168.86.1";
      # internalSubnet = "10.0.0.1/24";
      ipPool = import ./lib/ip-calculator.nix {
        defaultGateway = "192.168.86.1";
        subnet = "192.168.86.192/32";
        internalSubnet = "10.0.0.1/24";
      };

      # Relative path, because secrets are mounted at /mnt/secrets
      # in the luks usb drive on the host
      secrets-dir = "/mnt/secrets";

      terranix-storage = {
        terraform."required_providers"."incus" = {
          source = "registry.terraform.io/lxc/incus";
        };
        provider."incus" = { };

        resource."incus_storage_pool"."homeserver_lvm" = {
          name = "lvm";
          driver = "lvm";
          config = {
            size = "800GiB";
          };
        };

        resource."incus_storage_volume"."homeserver_zfs_tank_1tb" = {
          name = "zfs_tank_1tb";
          pool = "tank";
          config = {
            size = "1TiB";
          };
        };

        resource."incus_storage_volume"."homeserver_lvm_500gb" = {
          name = "lvm_500gb";
          pool = "lvm";
          config = {
            size = "500GiB";
          };
        };
      };

      darwinSystems = [
          "aarch64-darwin"
          "x86_64-darwin"
      ];
    in
    {
      nixosConfigurations = import ./hosts {
        inherit
          nixpkgs
          ipPool
          inputs
          self
          ;
      };

      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system:
            {"mac-mini-m4" = darwin.lib.darwinSystem {
            inherit system;
            specialArgs = { inherit inputs; };
            modules = [
                ./darwin-hosts/mac-mini-m4.nix
            ];
            };}
        );

      apps.x86_64-linux = {
        deploy =
          {
            type = "app";
            program = toString (
              pkgs.writers.writeBash "test" ''
                echo deploy $1
              ''
            );
            all = {
              type = "app";
              program = toString (
                pkgs.writers.writeBash "deploy" ''
                  ${builtins.concatStringsSep "\n" (
                    builtins.attrValues (
                      builtins.mapAttrs (name: value: ''
                        ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake .#${name} --target-host ${value.config.ip}
                      '') self.nixosConfigurations
                    )
                  )}
                ''
              );

            };
          }
          // (builtins.mapAttrs (name: value: {
            type = "app";
            program = toString (
              pkgs.writers.writeBash "deploy" ''
                  #!/bin/bash
                echo deploy ${name} ${value.config.ip}
                ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake .#${name} --target-host ${value.config.ip}
              ''
            );
          }) self.nixosConfigurations);

        generate-ssh-keys = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "push-secrets" ''
              ${pkgs.python3}/bin/python3 ${./scripts/generate_ssh_keys.py} --output-dir ${secrets-dir} ${builtins.concatStringsSep " " (builtins.attrNames self.nixosConfigurations)}
            ''
          );
        };

        push-ssh-keys = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "push-secrets" ''
              ${builtins.concatStringsSep "\n" (
                builtins.map (name: ''
                  # copy public keys to ./secrets/public-keys
                  incus file push ${secrets-dir}/${name}_id_ed25519 ${name}/root/.ssh/id_ed25519 -p
                  incus file push ${secrets-dir}/${name}_id_ed25519.pub ${name}/root/.ssh/id_ed25519.pub -p
                '') (builtins.attrNames self.nixosConfigurations)
              )}
            ''
          );
        };

        import-incus-images = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "import-incus-images" ''
              incus image import --alias nixos-lxc-base \
              ${self.images.incus-lxc-base.metadata}/tarball/nixos-system-x86_64-linux.tar.xz \
              ${self.images.incus-lxc-base.img}/nixos-lxc-image-x86_64-linux.squashfs
            ''
          );
        };

        terranix-config = (
          import ./apps/terranix-config.nix {
            inherit
              terranix
              pkgs
              nixpkgs
              terranix-storage
              self
              ;
          }
        );
      };

    };
}
