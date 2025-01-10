{
  disko.devices.disk.main = {
    device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_disk0_cumulus";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02"; # for grub MBR
        };
	ESP = {
	  size = "512M";
	  type = "EF00";
	  content = {
	    type = "filesystem";
	    format = "vfat";
	    mountpoint = "/boot";
	    mountOptions = [ "umask=0077" ];
	  };
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
}

