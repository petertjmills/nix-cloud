{ pkgs, ... }:
{
  imports = [
    "${pkgs}/nixos/modules/virtualisation/lxc-container.nix"
  ];

  services.cloud-init.network.enable = true;
  alias = "nixos-lxc-base";

}
