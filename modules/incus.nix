{
  pkgs,
  ip,
  defaultGateway,
  hostname,
  ...
}:
{

  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      8443
      53
      67
    ];
    allowedUDPPorts = [
      53
      67
    ];
  };
  networking.firewall.trustedInterfaces = [ "incusbr0" ];
  # networking.bridges = {
  # "br0" = {
  # interfaces = [ "enp1s0" ];
  # };
  # };
  # networking.interfaces.br0.ipv4.addresses = [
  # {
  # address = ip.address;
  # prefixLength = 24;
  # }
  # ];
  networking.useDHCP = false;
  networking.defaultGateway = defaultGateway;
  networking.hostName = hostname;
  networking.nameservers = [ "8.8.8.8" ];

  services.lvm.boot.thin.enable = true;
  services.lvm.enable = true;

  virtualisation.incus = {
    enable = true;
    package = pkgs.incus;
    ui.enable = true;
    preseed = {
      config."core.https_address" = "[::]:8443";
      config."images.auto_update_interval" = "0";
      networks = [ ];
      storage_pools = [

      ];
      profiles = [
        {
          config."agent.nic_config" = true;
          devices.enp1s0 = {
            name = "enp1s0";
            nictype = "bridged";
            parent = "br0";
            type = "nic";
          };
          devices.root = {
            path = "/";
            pool = "lvm";
            type = "disk";
          };
          name = "default";
        }
      ];
    };
  };

}
