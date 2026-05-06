{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, utils, ... }@inputs:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = { };
        packages.website = pkgs.callPackage ./nix/packages/website.nix { };

        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.pnpm_10
            pkgs.nodejs
          ];

          shellHook = '''';
        };
      }
    );
}
