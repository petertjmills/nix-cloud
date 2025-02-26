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

      defaultGateway = "192.168.86.1";
      internalSubnet = "10.0.0.1/24";
      ipPool = import ./lib/ip-calculator.nix "192.168.86.192/26" internalSubnet;

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
      nixosConfigurations =
        let
          mkNixosSystem = import ./lib/mk-nixos-system.nix {
            inherit
              nixpkgs
              inputs
              defaultGateway
              self
              internalSubnet
              ;
          };
        in
        {
          sky = mkNixosSystem {
            name = "sky";
            ip = ipPool 0;

            modules = [
              ./machine/home-server.nix
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
                # required to avoid
                # error: this system does not support the kernel namespaces that are required for sandboxing; use '--no-sandbox' to disable sandboxing
                "security.nesting" = true;
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
              ./machine/incus-container.nix
              ./modules/zsh.nix
              ./modules/opentofu.nix
              {
                environment.systemPackages = [
                  pkgs.nixd
                  pkgs.nixfmt-rfc-style
                  pkgs.incus
                ];
              }
            ];
          };

          stratocumulus = mkNixosSystem {
            name = "stratocumulus";
            ip = ipPool 2;
            terranix = {
              image = "nixos-lxc-base";
              config = {
                "boot.autostart" = true;
              };
            };

            modules = [
              ./machine/incus-container.nix
              ./modules/dns.nix
            ];
          };

          cumulonimbus = mkNixosSystem {
            name = "cumulonimbus";
            ip = ipPool 3;
            terranix = {
              image = "nixos-lxc-base";
              config = { };
              # {
              #   storage = {
              #     pool = "tank";
              #     source = "zfs_tank_1tb";
              #     type = "disk";
              #   };
              # };
              device = [
                {
                  name = "zfs_storage";
                  type = "disk";
                  properties = {
                    pool = "tank";
                    source = "zfs_tank_1tb";
                    path = "/zfs_data";
                  };
                }
                {
                  name = "lvm_storage";
                  type = "disk";
                  properties = {
                    pool = "lvm";
                    source = "lvm_500gb";
                    path = "/lvm_data";
                  };
                }
              ];
            };

            modules = [
              ./machine/incus-container.nix
              ./modules/seaweedfs.nix

            ];
          };

          nimbostratus = mkNixosSystem {
            name = "nimbostratus";
            ip = ipPool 4;
            terranix = {
              image = "nixos-vm-base";
              config = { };
              limits = {
                cpu = 4;
                memory = "4GiB";
              };
              device = [
                {
                  name = "gpu";
                  type = "pci";
                  properties = {
                    address = "0000:00:02.0";
                  };
                }
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
              # ./modules/zsh.nix
              ./modules/jellyfin.nix
              ./modules/seaweedfs.nix
              (
                { ... }:
                {
                  services.seaweedfs = {
                    enable = true;
                    group = "media";
                    mount = {
                      enable = true;
                      instances = [
                        {
                          name = "zfsmedia";
                          mountPoint = "/zfsmedia";
                          path = "/buckets/zfs-media";
                          filerAddress = "10.0.0.4:8888";
                        }
                        {
                          name = "lvmmedia";
                          mountPoint = "/lvmmedia";
                          path = "/buckets/lvm-media";
                          filerAddress = "10.0.0.4:8888";
                        }
                      ];
                    };
                  };
                  swapDevices = [
                    {
                      device = "/swapfile";
                      # 4gb
                      size = 4 * 1024;
                      randomEncryption.enable = true;
                    }
                  ];
                }
              )
            ];
          };

          cirrus = mkNixosSystem {
            name = "cirrus";
            ip = ipPool 5;
            modules = [ ];
          };

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
