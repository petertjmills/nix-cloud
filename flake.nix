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

      terranix-storage = rec {
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

      apps.x86_64-linux = {

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

        import-incus-images = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "import-incus-images" (''
              incus image import --alias nixos-lxc-base \
              ${self.images.incus-lxc-base.metadata}/tarball/nixos-system-x86_64-linux.tar.xz \
              ${self.images.incus-lxc-base.img}/nixos-lxc-image-x86_64-linux.squashfs
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

            terranixVms = nixpkgs.lib.filterAttrs (
              name: config: config._module.specialArgs.terranix != null
            ) self.nixosConfigurations;
          in
          {
            apply = {
              type = "app";
              program = toString (
                pkgs.writers.writeBash "apply" ''
                  if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
                  cp ${allVMsTerraformConfiguration} config.tf.json
                  ${tofu}/bin/tofu init
                  ${
                    # Import all nixos configurations in case they already exist
                    builtins.concatStringsSep "\n" (
                      builtins.map (name: ''
                        ${tofu}/bin/tofu import incus_instance.${name} ${name},image=${
                          terranixVms.${name}._module.specialArgs.terranix.resource.incus_instance.${name}.image
                        }
                      '') (builtins.attrNames terranixVms)
                    )
                  }

                  ${tofu}/bin/tofu apply
                  # rm -f config.tf.json
                ''
              );
            };

            plan = {
              type = "app";
              program = toString (
                pkgs.writers.writeBash "plan" ''
                  if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
                  cp ${allVMsTerraformConfiguration} config.tf.json
                  ${tofu}/bin/tofu init
                  ${tofu}/bin/tofu plan
                  # rm -f config.tf.json
                ''
              );
            };

            import = {
              type = "app";
              program = toString (
                pkgs.writers.writeBash "import" ''
                  if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
                  cp ${allVMsTerraformConfiguration} config.tf.json
                  ${tofu}/bin/tofu init
                  ${tofu}/bin/tofu import
                  # rm -f config.tf.json
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
