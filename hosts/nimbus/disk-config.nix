{ lib, ... }:
{
  disko.devices.disk = {
    disk1 = {
      device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_disk0nimbus-os";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # for grub MBR
          };
          swap = {
            size = "4G";
            content = {
              type = "swap";
              discardPolicy = "both";
              resumeDevice = false;
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };

    # disk2 = {
    #   device = lib.mkDefault "/dev/sdb";
    #   type = "disk";
    #   content = {
    #     type = "gpt";
    #     partitions = {
    #       root = {
    #         size = "100%";
    #         content = {
    #           type = "filesystem";
    #           format = "ext4";
    #           mountpoint = "/data";
    #         };
    #       };
    #     };
    #   };
    # };
  };
}

