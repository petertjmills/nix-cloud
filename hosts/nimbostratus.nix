{
  config,
  pkgs,
  lib,
  ipPool,
  inputs,
  ...
}:
let
  ip = ipPool 5;
in
{
  imports = [
    ../machines/incus-vm.nix
    ../modules/seaweedfs.nix
    ../modules/jellyfin.nix
  ];

  networking.hostName = "nimbostratus";
  ip = ip.internalIp;
  lanIp = ip.address;

  terranix.resource."incus_instance"."${config.networking.hostName}" = {
    limits = {
      cpu = 4;
      memory = "4GiB";
    };
    device = [
      {
        name = "gpu";
        type = "pci";
        properties = {
          address = "0000:00:02.0";
        };
      }
      {
        name = "root";
        type = "disk";
        properties = {
          path = "/";
          pool = "lvm";
          size = "50GiB";
        };
      }
    ];
  };

  services.seaweedfs = {
    group = "media";
    mount = {
      enable = true;
      instances = [
        {
          name = "zfsmedia";
          mountPoint = "/zfsmedia";
          path = "/buckets/zfs-media";
          filerAddress = "${inputs.self.nixosConfigurations.cumulonimbus.config.ip}:8888";
        }
        {
          name = "lvmmedia";
          mountPoint = "/lvmmedia";
          path = "/buckets/lvm-media";
          filerAddress = "${inputs.self.nixosConfigurations.cumulonimbus.config.ip}:8888";
        }
      ];
    };
  };

  swapDevices = [
    {
      device = "/swapfile";
      # 4gb
      size = 4 * 1024;
      randomEncryption.enable = true;
    }
  ];
}
