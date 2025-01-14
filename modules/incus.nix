{
  networking.nftables.enable = true;
  # networking.firewall.trustedInterfaces = [ "incusbr0" ];
  networking.bridges = {
    "br0" = {
      interfaces = [ "enp1s0" ];
    };
  };
  networking.interfaces.br0.ipv4.addresses = [
    {
      address = "192.168.86.60";
      prefixLength = 24;
    }
  ];
  networking.useDHCP = false;
  networking.defaultGateway = "192.168.86.1";
  networking.nameservers = [ "8.8.8.8" ];
  virtualisation.incus = {
    enable = true;
    ui.enable = true;
    preseed = {
      config."core.https_address" = "[::]:8443";
      config."images.auto_update_interval" = "0";
      networks = [ ];
      storage_pools = [
        # Only run this once. if it fails use incus storage
        # {
        #   config.source = "tank";
        #   name = "incus_zfs_pool";
        #   driver = "zfs";
        # }
      ];
      profiles = [
        {
          devices.eth0 = {
            name = "eth0";
            nictype = "bridged";
            parent = "br0";
            type = "nic";
          };
          devices.root = {
            path = "/";
            pool = "incus_zfs";
            type = "disk";
          };
          name = "default";
        }
      ];
      projects = [ ];
      cluster = null;
    };
  };

}
