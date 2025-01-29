{
  description = "My nix cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    terranix.url = "github:terranix/terranix";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:petertjmills/nixvim";

    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      terranix,
      disko,
      sops-nix,
      ...
    }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      ipPool = import ./lib/ip-calculator.nix "192.168.86.192/26";
      defaultGateway = "192.168.86.1";
      # See default.nix to why the path doesn't have ./
      secrets-dir = "/mnt/secrets";
    in
    {
      nixosConfigurations = {

        minimal = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs defaultGateway;
            ip = ipPool 0;
            hostname = "minimal";

          };
          modules = [
            inputs.disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./modules
            ./disko/nvme_uefi.nix
            # TODO: host_sky might not be a very good name...
            ./modules/host_sky.nix
            ./modules/networking.nix
            ./modules/zfs.nix
            ./modules/zsh.nix
          ];
        };

        x86_64-linux-minimal-cd = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs defaultGateway;
            ip = ipPool 0;
            hostname = "minimal";
          };
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ./modules
            ./modules/networking.nix
          ];
        };

        sky = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs defaultGateway;
            ip = ipPool 0;
            hostname = "sky";
          };
          modules = [
            inputs.disko.nixosModules.disko
            inputs.sops-nix.nixosModules.sops
            ./modules
            ./disko/nvme_uefi.nix
            # TODO: host_sky might not be a very good name...
            ./modules/host_sky.nix
            ./modules/zsh.nix
            ./modules/zfs.nix
            # Incus module handles ZFS and networking configs
            ./modules/incus.nix
            ./modules/nvim.nix
          ];
        };

      } // self.core-vms;

      core-vms = {
        cumulus = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs defaultGateway;
            ip = ipPool 1;
            hostname = "cumulus";
            vm-config = {
              config."limits.cpu" = "2";
              config."limits.memory" = "2GiB";

              config."boot.autostart" = true;

            };
          };
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/lxd-virtual-machine.nix"
            inputs.sops-nix.nixosModules.sops
            ./modules
            ./modules/networking.nix
            ./modules/zsh.nix
            ./modules/nvim.nix
            ./modules/sops.nix
            (
              { pkgs, ... }:
              {
                environment.systemPackages = [
                  pkgs.incus
                ];
              }
            )

          ];
        };

        stratocumulus = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs defaultGateway;
            ip = ipPool 2;
            hostname = "stratocumulus";
            vm-config = {
            };
          };
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/lxd-virtual-machine.nix"
            ./modules
            ./modules/networking.nix
            ./modules/dns.nix
          ];
        };

        cumulonimbus = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs defaultGateway;
            ip = ipPool 3;
            hostname = "cumulonimbus";
            vm-config = {
              devices.storage = {
                pool = "tank";
                source = "zfs_tank_1tb";
                type = "disk";
              };
            };
          };
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/lxd-virtual-machine.nix"
            ./modules
            ./modules/networking.nix
            {
              fileSystems."/data" = {
                device = "/dev/disk/by-uuid/a4e5bfd5-b2d7-4b19-b3f9-29f9ba1bc96e";
                fsType = "ext4";
              };
            }
            ./modules/minio.nix
          ];
        };
      };

      apps.x86_64-linux = {

        generate-ssh-keys = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "generate-secrets" (''
              #check to see if dir exists
              if [ ! -d ${secrets-dir}/masterkey ]; then
                echo "Master key dir is missing. Drive may not be mounted"
                exit 1
              fi

              # ssh-keygen -t ed25519 -f ${secrets-dir}/masterkey/master_id_ed25519 -N "" # Generate ssh key
              # copy public keys to ./secrets/public-keys
              # cp ${secrets-dir}/masterkey/master_id_ed25519.pub ./secrets/public-keys/master_id_ed25519.pub

              ${builtins.concatStringsSep "\n" (
                builtins.map (name: ''
                  ssh-keygen -t ed25519 -f ${secrets-dir}/${name}_id_ed25519 -N ""
                  cp ${secrets-dir}/${name}_id_ed25519.pub ./secrets/public-keys/${name}_id_ed25519.pub
                '') (builtins.attrNames self.nixosConfigurations)
              )}
            '')
          );
        };

        push-ssh-keys = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "push-secrets" (''
              ${builtins.concatStringsSep "\n" (
                builtins.map (name: ''
                  # copy public keys to ./secrets/public-keys
                  incus file push ${secrets-dir}/${name}_id_ed25519 ${name}/root/.ssh/id_ed25519 -p
                  incus file push ${secrets-dir}/${name}_id_ed25519.pub ${name}/root/.ssh/id_ed25519.pub -p
                '') (builtins.attrNames self.nixosConfigurations)
              )}
            '')
          );
        };

      };

    };
}
