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
  # Or incus will crash the Network interface when vm/container is stopped
  # boot.kernelPackages = pkgs.linuxPackages_latest;

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

  time.timeZone = "Europe/London";
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "tank" ];
  networking.hostId = "d0a95792";

  fileSystems."/mnt/zfs" = {
    device = "tank";
    fsType = "zfs";
  };
  systemd.enableEmergencyMode = false;

  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
  ];

  networking.firewall = {
    enable = true;
  };

  networking.bridges = {
    "br0" = {
      interfaces = [ "enp1s0" ];
    };
  };

  networking.interfaces."br0".ipv4 = {
    addresses = [
      {
        address = "192.168.86.192";
        prefixLength = 24;
      }
    ];
  };

  networking.defaultGateway = {
    address = "192.168.86.1";
    interface = "br0";
  };

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
