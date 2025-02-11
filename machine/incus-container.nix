{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  services.cloud-init.network.enable = true;

}
