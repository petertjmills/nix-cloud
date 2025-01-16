{ ip, defaultGateway, hostname, ... }:
{
  networking.useDHCP = false;
  networking.hostName = hostname;
  networking.defaultGateway = defaultGateway;
  networking.interfaces.enp1s0.ipv4.addresses = [
    {
      address = ip.address;
      prefixLength = 24;
    }
  ];
}
