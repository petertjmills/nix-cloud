{
  modulesPath,
  pkgs,
  ip,
  inputs,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/incus-virtual-machine.nix"
  ];

  virtualisation.incus.agent.enable = true;
  virtualisation.incus.package = pkgs.incus;
  networking.interfaces.enp1s0.ipv4 = {
    addresses = [
      {
        address = ip.internalIp;
        prefixLength = 24;
      }
    ];
  };
  networking.defaultGateway = inputs.self.nixosConfigurations.sky._module.specialArgs.ip.internalIp;
}
