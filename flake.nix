{
  description = "My nix cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    terranix.url = "github:terranix/terranix";
    terranix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:petertjmills/nixvim";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
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

    secrets = {
      url = "git+ssh://git@github.com/petertjmills/secrets.git";
      flake = false;
    };

    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
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
      darwinPkgs = nixpkgs.legacyPackages.aarch64-darwin;
      unstableDarwin = inputs.unstable.legacyPackages.aarch64-darwin;

      # defaultGateway = "192.168.86.1";
      # internalSubnet = "10.0.0.1/24";
      ipPool = import ./lib/ip-calculator.nix {
        defaultGateway = "192.168.86.1";
        subnet = "192.168.86.192/32";
        internalSubnet = "10.0.0.1/24";
      };

      linuxSystems = [
        "x86_64-linux"
      ];

      darwinSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    {
      nixosConfigurations = {
        "sky" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./machines/home-server.nix
            ./hosts/sky.nix
          ];
        };

        "cirrus" = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./machines/hetzner.nix
            ./hosts/cirrus.nix
          ];
        };
      };

      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system: {
        "mac-mini-m4" = darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs unstableDarwin; };
          modules = [
            ./darwin-hosts/mac-mini-m4.nix
          ];
        };
      });

      apps = {
        nixos-switch = {
          type = "app";
          program = toString (
            darwinPkgs.writers.writeBash "nixos-switch" ''
              ${darwinPkgs.nixos-rebuild}/bin/nixos-rebuild switch $1
            ''
          );
        };
      };

      packages = nixpkgs.lib.genAttrs darwinSystems (system: {
        tldx = import ./packages/tldx.nix { pkgs = darwinPkgs; };
      });

    };

}
