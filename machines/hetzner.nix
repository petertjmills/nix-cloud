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
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
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
    networking.nameservers = [
      "9.9.9.9"
      "1.1.1.1"
    ];
    nixpkgs.hostPlatform = lib.mkForce "aarch64-linux";
    # nixpkgs.system = "aarch64-linux";
    #

    services.openssh.enable = true;
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8tQOhDkrQO4q3W7JdernvtL1v+aiNsjozN41qrfs2n Silversurfer"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyxwQIShLIk/qHVnEkRWC+7/V82brDH3s0tBwpnttVi macmini"
    ];

    system.stateVersion = "24.05";

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
