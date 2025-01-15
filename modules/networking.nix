{ ip, defaultGateway, ... }:
{
  networking.useDHCP = false;
  networking.defaultGateway = defaultGateway;
  networking.interfaces.enp1s0.ipv4.addresses = [
    {
      address = ip.address;
      prefixLength = 24;
    }
  ];
}
