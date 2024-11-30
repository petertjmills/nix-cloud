# required_providers {
#     proxmox = {
#       source  = "telmate/proxmox"
#       version = "3.0.1-rc3"
#     }
#   }
{ ... }:
{
  terraform.required_providers = {
    proxmox = {
      source = "registry.terraform.io/telmate/proxmox";
      version = "3.0.1-rc6";
    };

    hcloud = {
      source = "registry.terraform.io/hetznercloud/hcloud";
      version = "1.45.0";
    };
  };

  provider.proxmox = {
    pm_api_url = "http://proxmox.server:8006/api2/json";
    pm_tls_insecure = true;
  };

  # resource.hcloud_server.stratus = {
  #   name = "stratus";
  #   server_type = "cax11";
  #   image = "debian-12";
  #   location = "nbg1";
  #   ssh_keys = [
  #     "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPEhVfbVbix9lPz1+hQAeo7qRtQwIs6+ev22HLa4IiI+ root@cumulus"
  #   ];
  #   iso = "nixos-minimal-24.05.1503.752c634c09ce-aarch64-linux.iso";
  # };

  resource.proxmox_vm_qemu.nixmusic = {
    name = "nixmusic";
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
        serial = "disk0aaa";
      };
      ide.ide0.cdrom = {
        iso = "local:iso/nixos-24.05.20240630.7dca152-x86_64-linux.iso";
      };
    };

    usbs = {
      usb0.mapping.mapping_id = "scarlett";
    };

  };

  resource.proxmox_vm_qemu.cumulus = {
    name = "cumulus";
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
        size = "64G";
        storage = "local-lvm";
        iothread = true;
        serial = "disk0_cumulus";
      };
      ide.ide0.cdrom = {
        iso = "local:iso/nixos-24.05.20240630.7dca152-x86_64-linux.iso";
      };
    };
  };
}
