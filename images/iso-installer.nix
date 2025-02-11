{pkgs, ...}: {
  import = [
    "${pkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # additional config...
}
