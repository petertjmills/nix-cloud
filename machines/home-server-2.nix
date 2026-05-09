{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.default
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.channel.enable = false;
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8tQOhDkrQO4q3W7JdernvtL1v+aiNsjozN41qrfs2n Silversurfer"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyxwQIShLIk/qHVnEkRWC+7/V82brDH3s0tBwpnttVi macmini"
  ];

  system.stateVersion = "24.05";
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

  time.timeZone = "Europe/London";

  systemd.enableEmergencyMode = false;

  networking = {
    bridges."br0".interfaces = [ "enp3s0" ];
    interfaces."br0".useDHCP = true;
    useDHCP = false;

    firewall = {
      enable = true;
    };

    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];

    nat = {
      enable = true;
      internalInterfaces = [ "vb-+" ];
      externalInterface = "br0";
    };
  };

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
