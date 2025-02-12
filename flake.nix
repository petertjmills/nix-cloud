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

      # Relative path, because secrets are mounted at /mnt/secrets
      # in the luks usb drive on the host
      secrets-dir = "/mnt/secrets";

      terranix-storage = rec {
        terraform."required_providers"."incus" = {
          source = "registry.terraform.io/lxc/incus";
        };
        provider."incus" = { };
        # resource."incus_storage_pool"."homeserver_tank" = {
        #   name = "zfs_tank";
        #   driver = "zfs";
        #   source = "tank";
        # };

        resource."incus_storage_pool"."homeserver_lvm" = {
          name = "lvm";
          driver = "lvm";
          config = {
            size = "800GiB";
          };

        };

        # resource."incus_storage_volume"."homeserver_zfs_tank_1tb" = {
        #   name = "zfs_tank_1tb";
        #   pool = resource."incus_storage_pool"."homeserver_tank".name;
        #   size = "1TiB";
        # };
      };

      # terranix = import ./lib/terranix-utils.nix {
      #   inherit nixpkgs terranix-storage self;
      # };

      mkNixosSystem = import ./lib/mk-nixos-system.nix {
        inherit
          nixpkgs
          inputs
          defaultGateway
          self
          ;
      };

      mkImage = import ./lib/mk-image.nix {
        inherit nixpkgs;
      };

    in
    {
      nixosConfigurations = {

        # installer = mkNixosSystem {
        #   name = "installer";
        #   # image = ./images/iso-installer.nix;
        #   # Needs something else here?
        # };

        sky = mkNixosSystem {
          name = "sky";

          ip = ipPool 0;

          modules = [
            ./modules/zsh.nix
            ./modules/incus.nix
          ];
        };

        cumulus = mkNixosSystem {
          name = "cumulus";

          ip = ipPool 1;

          terranix = {
            image = "nixos-lxc-base";

            config = {
              "boot.autostart" = true;
            };

            limits = {
              cpu = 2;
              memory = "4GiB";
            };

            device = [
              {
                name = "root";
                type = "disk";
                properties = {
                  path = "/";
                  pool = "lvm";
                  size = "50GiB";
                };
              }
            ];
          };

          modules = [
            ./machine/incus-vm.nix
            ./modules/zsh.nix
            ./modules/opentofu.nix
            {
              environment.systemPackages = with pkgs; [
                pkgs.nixd
                pkgs.nixfmt-rfc-style
              ];
            }
          ];
        };

        stratocumulus = mkNixosSystem {
          name = "stratocumulus";

          ip = ipPool 2;

          modules = [
            # ./machine/incus-container.nix

            ./modules/zsh.nix
          ];
        };

        cumulonimbus = mkNixosSystem {
          name = "cumulonimbus";

          ip = ipPool 3;
          # terranix = {

          #   config = { };
          #   devices = {
          #     storage = {
          #       pool = "tank";
          #       source = "zfs_tank_1tb";
          #       type = "disk";
          #     };
          #   };
          # };

          modules = [
            ./machine/incus-container.nix
            {
              fileSystems = {
                "/data" = {
                  device = "/dev/disk/by-uuid/a4e5bfd5-b2d7-4b19-b3f9-29f9ba1bc96e";
                  fsType = "ext4";
                };
              };
            }
            ./modules/zsh.nix
          ];
        };
      };

      images = {
        incus-lxc-base = mkImage {
          name = "incus-lxc-base";
          module = ./images/incus-lxc-base.nix;
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

        import-images = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "import-images" (''
              ${builtins.concatStringsSep "\n" (
                builtins.map (name: ''
                  incus image import --alias ${name} ${self.images.${name}.img} ${self.images.${name}.metadata}
                '') (builtins.attrNames self.images)
              )}
            '')
          );
        };

        terranix-config =
          let
            system = "x86_64-linux";
            tofu = import ./packages/opentofu.nix { inherit pkgs; };
            allVMsTerraformConfiguration = terranix.lib.terranixConfiguration {
              inherit system;
              modules = [
                (import ./lib/terranix-utils.nix {
                  inherit nixpkgs terranix-storage self;
                })
              ];
            };
          in
          {
            apply = {
              type = "app";
              program = toString (
                pkgs.writers.writeBash "apply" ''
                  if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
                  cp ${allVMsTerraformConfiguration} config.tf.json
                  ${tofu}/bin/tofu init
                  ${tofu}/bin/tofu apply
                  rm -f config.tf.json
                ''
              );
            };
            destroy = {
              type = "app";
              program = toString (
                pkgs.writers.writeBash "destroy" ''
                  if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
                  cp ${allVMsTerraformConfiguration} config.tf.json
                  ${tofu}/bin/terraform destroy
                  rm -f config.tf.json
                ''
              );
            };
          };

      };

    };
}
