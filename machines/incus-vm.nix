{
  modulesPath,
  pkgs,
  ip,
  inputs,
  lib,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/incus-virtual-machine.nix"
  ];

  virtualisation.incus.agent.enable = true;
  virtualisation.incus.package = pkgs.incus;
  networking.interfaces.enp1s0.useDHCP = true;
}
