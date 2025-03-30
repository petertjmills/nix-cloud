{
  modulesPath,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko

    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  options.ip = lib.mkOption {
    type = lib.types.str;
    default = "";
    description = "The IP address of the server";
  };

  config = {
    boot.initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
      "sr_mod"
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelParams = [ ];
    # nixpkgs.hostPlatform = "aarch64-linux";
    boot.loader.grub.enable = true;
    # Required for Hetzner UEFI boot.
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.efiInstallAsRemovable = true;
    # boot.loader.grub.device = "/dev/sda";
    #
    networking.firewall.enable = true;
    nixpkgs.hostPlatform = lib.mkForce "aarch64-linux";

    disko.devices = {
      disk = {
        main = {
          device = "/dev/sda";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                size = "1M";
                type = "EF02"; # for grub MBR
                priority = 1;
              };
              ESP = {
                size = "500M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
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
      };
    };
  };
}
