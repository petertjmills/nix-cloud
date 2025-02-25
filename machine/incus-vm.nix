{
  modulesPath,
  pkgs,
  ip,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/incus-virtual-machine.nix"
  ];
  networking.useDHCP = false;
  services.cloud-init.network.enable = true;
  services.cloud-init.enable = true;
  networking.interfaces.enp1s0.ipv4 = {
    addresses = [
      {
        address = ip.address;
        prefixLength = 32;
      }
    ];

    routes = [
      {
        address = "0.0.0.0";
        prefixLength = 0;
        via = "169.254.0.1";
        options.onlink = "";
      }
    ];
  };

  virtualisation.incus.agent.enable = true;
  virtualisation.incus.package = pkgs.incus;

}
