{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/incus-virtual-machine.nix"
  ];

  services.cloud-init.network.enable = true;

}
