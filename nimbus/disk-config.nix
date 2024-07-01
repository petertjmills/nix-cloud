{ lib, ... }:
{
  disko.devices.disk.disk1 = {
    device = lib.mkDefault "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "primary";
        };
        root = {
          end = "-8GB";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
        swap = {
          size = "100%";
          content = {
            type = "swap";
            resumeDevice = true;
          };
        };
      };
    };
  };
}

