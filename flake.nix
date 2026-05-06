{
  description = "My nix cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    utils.url = "github:numtide/flake-utils";

    terranix.url = "github:terranix/terranix";
    terranix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:petertjmills/nixvim";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
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

    ory-nix-auth.url = "git+ssh://git@github.com/metachroma/ory-nix-auth.git";
    ory-nix-auth.inputs.nixpkgs.follows = "nixpkgs";

    opencode.url = "github:anomalyco/opencode";
    # opencode.inputs.nixpkgs.follows = "nixpkgs";

    escpos-server.url = "github:petertjmills/escpos-server";
    escpos-server.inputs.nixpkgs.follows = "nixpkgs";
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
      utils,
      ...
    }@inputs:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        darwinPkgs = nixpkgs.legacyPackages.aarch64-darwin;
        unfreeDarwinPkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };

        unstable = import inputs.unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        unstableDarwin = inputs.unstable.legacyPackages.aarch64-darwin;

        darwinSystems = [
          "aarch64-darwin"
          "x86_64-darwin"
        ];
      in
      {

        devShells.default = pkgs.mkShell {
          buildInputs = [
            (pkgs.callPackage ./packages/plann.nix { })
            unstableDarwin.container
          ];

          shellHook = "";
        };

        nixosConfigurations = {

          "qemu-auth" = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = { inherit inputs unstable; };
            modules = [
              (import ./machines/qemu.nix pkgs)
              ./modules/auth.nix
            ];
          };
        };

        darwinConfigurations = {
          "mac-mini-m4" = darwin.lib.darwinSystem {
            inherit system;
            specialArgs = { inherit inputs unstableDarwin unfreeDarwinPkgs; };
            modules = [
              ./darwin-hosts/mac-mini-m4.nix
            ];
          };
        };

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
          qemuvm = self.nixosConfigurations.${system}.qemu-auth.config.system.build.vm;
        });

        templates.dev = {
          path = ./templates/dev;
          description = "My standard dev template";
          welcomeText = ''
            Run `direnv allow` to get started
          '';
        };

        templates.webdev = {
          path = ./templates/webdev;
          description = "My standard web dev template";
          welcomeText = ''
            Run `direnv allow` to get started
          '';
        };
      }
    )
    // (
      let
        pkgsArm = nixpkgs.legacyPackages.aarch64-linux;
        unstable = import inputs.unstable {
          system = "x86_64-linux";
          # config.allowUnfree = true;
        };
      in
      {
        nixosConfigurations = {
          "cirrus" = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              ./machines/hetzner.nix
              ./hosts/cirrus.nix
            ];
          };

          "sky" = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs unstable; };
            modules = [
              ./machines/home-server.nix
              ./hosts/sky.nix
            ];
          };

          "oci-test" = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = { inherit inputs; };
            modules = [

            ];
          };
        };
      }
    );
}
