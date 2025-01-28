{
  ip,
  defaultGateway,
  hostname,
  inputs,
  ...
}:
{
  # Disable wireless networking, as this breaks the use of networkmanager when building the ISO
  networking.wireless.enable = false;

  networking.useDHCP = false;
  networking.hostName = hostname;
  networking.defaultGateway = defaultGateway;
  networking.nameservers = [
    "${inputs.self.core-vms.stratocumulus._module.specialArgs.ip.address}"
  ];
  # networking.usePredictableInterfaceNames = false;
  networking.interfaces.enp1s0.ipv4.addresses = [
    {
      address = ip.address;
      prefixLength = 24;
    }
  ];
}
