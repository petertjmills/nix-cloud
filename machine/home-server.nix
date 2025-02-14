{ inputs,pkgs, ... }:
{
  imports = [inputs.disko.nixosModules.disko];

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;

  boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.extraPools = [ "tank" ];
    networking.hostId = "d0a95792";
    environment.systemPackages = [
      pkgs.zfs
    ];

  disko.devices.disk.main = {
    device = "/dev/nvme0n1";
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
