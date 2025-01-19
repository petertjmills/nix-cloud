{
  ip,
  defaultGateway,
  hostname,
  ...
}:
{
  # Disable wireless networking, as this breaks the use of networkmanager when building the ISO
  networking.wireless.enable = false;

  networking.useDHCP = false;
  networking.hostName = hostname;
  networking.defaultGateway = defaultGateway;
  # networking.usePredictableInterfaceNames = false;
  networking.interfaces.enp1s0.ipv4.addresses = [
    {
      address = ip.address;
      prefixLength = 24;
    }
  ];
}
