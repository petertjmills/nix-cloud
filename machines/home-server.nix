{
  pkgs,
  lib,
  ...
}:
{
  imports = [ ];

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "sd_mod"
    "sr_mod"
  ];
  boot.kernelParams = [
    "i915.force_probe=46d1"
    "i915.enable_guc=2"
    "intel_iommu=on"
    "iommu=pt"
    ''vfio-pci.ids="8086:46d1"''
  ];
  # Or incus will crash the Network interface when vm/container is stopped
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # networking.interfaces.enp1s0.ipv4.addresses = [
  #   {
  #     address = ip.address;
  #     prefixLength = 32;
  #   }
  # ];
  # networking.defaultGateway = {
  #   address = defaultGateway;
  #   interface = "enp1s0";
  # };

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

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
