{
  description = "My nix cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    terranix.url = "github:terranix/terranix";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:petertjmills/nixvim";

  };

  outputs =
    {
      self,
      nixpkgs,
      terranix,
      disko,
      ...
    }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      ipPool = import ./lib/ip-calculator.nix "192.168.86.192/26";
      defaultGateway = "192.168.86.1";
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
            ./modules
            ./disko/nvme_uefi.nix
            # TODO: host_sky might not be a very good name...
            ./modules/host_sky.nix
            ./modules/networking.nix
            ./modules/zsh.nix
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
            ./modules
            ./disko/nvme_uefi.nix
            # TODO: host_sky might not be a very good name...
            ./modules/host_sky.nix
            ./modules/zsh.nix
            # Incus module handles ZFS and networking configs
            ./modules/incus.nix
            ./modules/nvim.nix
          ];
        };

      };

      vms = {
        cumulus = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs defaultGateway;
            ip = ipPool 1;
            hostname = "cumulus";
          };
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/lxd-virtual-machine.nix"
            ./modules
            ./modules/networking.nix
            ./modules/zsh.nix
            ./modules/nvim.nix
          ];
        };
      };

      apps.x86_64-linux = {
        importtest = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "importtest" ''
              ${pkgs.incus}/bin/incus image import --alias tst ${inputs.self.vms.test.config.system.build.metadata}/tarball/nixos-system-x86_64-linux.tar.xz ${inputs.self.vms.test.config.system.build.qemuImage}/nixos.qcow2
            ''
          );
        };
      };

    };
}
