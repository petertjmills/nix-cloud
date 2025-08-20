{ pkgs, ... }:
pkgs.opentofu.withPlugins (
  ps: with ps; [
    incus
    hcloud
  ]
)
