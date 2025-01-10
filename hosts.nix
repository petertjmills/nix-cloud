{ pkgs, ... }: {
  default = {
    terranix = {
      name = "default";
      target_node = "yellowsubmarine";
      memory = "2048";
      cores = "2";
      scsihw = "virtio-scsi-single";

      network = {
        id = 0;
        bridge = "vmbr0";
        link_down = false;
        firewall = true;
        model = "virtio";
      };

      disks = {
        scsi.scsi0.disk = {
          size = "20G";
          storage = "local-lvm";
          iothread = true;
          serial = "disk0_default";
        };
        ide.ide0.cdrom = {
          iso = "local:iso/nixos-24.05.20240630.7dca152-x86_64-linux.iso";
        };
      };
    };

    disko.devices.disk.main = {
      device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_disk0_default";
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

    modules = [
      ({ modulesPath, ... }: {
        imports = [
          (modulesPath + "/profiles/qemu-guest.nix")
        ];
        boot.initrd.availableKernelModules = [ "virtio_scsi" ];
        boot.kernelParams = [ "boot.shell_on_fail" ];

        boot.loader.grub.enable = true;

        nix.settings.experimental-features = [ "nix-command" "flakes" ];

        networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
        networking.firewall.enable = true;
        services.openssh.enable = true;

        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8tQOhDkrQO4q3W7JdernvtL1v+aiNsjozN41qrfs2n Silversurfer"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyxwQIShLIk/qHVnEkRWC+7/V82brDH3s0tBwpnttVi macmini"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPEhVfbVbix9lPz1+hQAeo7qRtQwIs6+ev22HLa4IiI+ root@cumulus"
        ];
      })
    ];

    system = "x86_64-linux";
    os = "nixos";
  };

  test = {
    terranix = {
      name = "test";
      disks.scsi.scsi0.disk.size = "20G";
    };

    disko = { };

    system = "x86_64-linux";
    os = "nixos";

    modules = [
      (
        { pkgs, ... }: {
          environment.systemPackages = with pkgs; [
            vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
            wget
            git
            just
            nixpkgs-fmt
            neofetch
          ];
          networking.hostName = "test"; # Define your hostname.
        }
      )
    ];
  };

}
