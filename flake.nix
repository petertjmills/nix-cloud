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
    {
      nixosConfigurations = {
        sky = nixpkgs.lib.nixosSystem {
          modules = [
            inputs.disko.nixosModules.disko
            ./modules
            ./disko/nvme_uefi.nix
            ./modules/host_sky.nix
            ./modules/zsh.nix
            ./modules/incus.nix
            (
              { pkgs, ... }:
              {
                environment.systemPackages = [
                  inputs.nixvim.packages.x86_64-linux.default # TODO: this would be better as a module rather than a package like disko
                  pkgs.zfs
                  pkgs.neofetch
                  pkgs.git
                  pkgs.just
                ];
              }
            )
          ];
        };

        test = nixpkgs.lib.nixosSystem {
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/lxd-virtual-machine.nix"
            ./modules
          ];
        };
      };

    };
}
