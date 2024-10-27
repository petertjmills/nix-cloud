{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_disk0";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            swap = {
              size = "1G";
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
      secondary = {
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_disk1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/data";
              };
            };
          };
        };
      };
    };
  };
}

