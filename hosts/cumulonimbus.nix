{
  config,
  pkgs,
  ipPool,
  ...
}:
let
  ip = ipPool 4;
in
{
  imports = [
    ../machines/incus-container.nix
    ../modules/seaweedfs.nix
  ];

  networking.hostName = "cumulonimbus";
  ip = ip.internalIp;
  lanIp = ip.address;

  terranix.resource."incus_instance"."${config.networking.hostName}" = {
    limits = {
      cpu = "1";
      memory = "4GiB";
    };

    device = [
      {
        name = "zfs_storage";
        type = "disk";
        properties = {
          pool = "tank";
          source = "zfs_tank_1tb";
          path = "/zfs_data";
        };
      }
      {
        name = "lvm_storage";
        type = "disk";
        properties = {
          pool = "lvm";
          source = "lvm_500gb";
          path = "/lvm_data";
        };
      }
    ];
  };

  services.seaweedfs = {
    enable = true;
    enableServer = true;
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 4096;
    }
  ];

}
