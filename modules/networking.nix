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
  # networking.defaultGateway = defaultGateway;
  networking.nameservers = [
    "${inputs.self.nixosConfigurations.stratocumulus._module.specialArgs.ip.address}"
    "8.8.8.8"
  ];
  # networking.usePredictableInterfaceNames = false;
  # networking.interfaces.enp1s0.ipv4.addresses = [
  #   {
  #     address = ip.address;
  #     prefixLength = 32;
  #   }
  # ];
}
