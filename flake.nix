{
  description = "My nix cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    terranix.url = "github:terranix/terranix";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      terranix,
      disko,
      ...
    }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          (import ./packages/opentofu.nix)
        ];
      };

      hostconfig = import ./hosts.nix { inherit pkgs; };
      hosts = import ./lib/host_config.nix { inherit pkgs hostconfig; };

      terraformConfiguration = terranix.lib.terranixConfiguration {
        inherit pkgs;
        modules = [
          {
            terraform.required_providers = {
              proxmox = {
                source = "registry.terraform.io/telmate/proxmox";
                version = "3.0.1-rc6";
              };

              hcloud = {
                source = "registry.terraform.io/hetznercloud/hcloud";
                version = "1.48.1";
              };
            };

            provider.proxmox = {
              pm_api_url = "http://proxmox.server:8006/api2/json";
              pm_tls_insecure = true;
            };
            resource.proxmox_vm_qemu = builtins.mapAttrs (name: value: value.terranix) hosts;
          }
        ];
      };

    in
    {
      nixosConfigurations = builtins.mapAttrs (
        name: value:
        nixpkgs.lib.nixosSystem {
          system = value.system;
          modules = [
            disko.nixosModules.disko
            {
              disko = value.disko;
            }
          ] ++ value.modules;
        }
      ) hosts;

      apps.x86_64-linux = {
        # nix run ".#apply"
        apply = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "apply" ''
              if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
              cp ${terraformConfiguration} config.tf.json \
                && ${pkgs.opentofu}/bin/tofu init \
                && ${pkgs.opentofu}/bin/tofu apply
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
                && ${pkgs.opentofu}/bin/tofu init \
                && ${pkgs.opentofu}/bin/tofu destroy
            ''
          );
        };

        show = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "destroy" ''
              echo ${hosts.test.system}
            ''
          );
        };
      };
    };
}
