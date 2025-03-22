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

      terraformConfiguration = terranix.lib.terranixConfiguration {
        system = "x86_64-linux";
        modules = [
          (nixpkgs.lib.attrsets.foldlAttrs (acc: name: value: {
            terranixM = (nixpkgs.lib.attrsets.recursiveUpdate acc.terranixM (value.config.terranix or { }));
          }) { terranixM = { }; } self.nixosConfigurations).terranixM
          terranix-storage
        ];
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
