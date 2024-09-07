terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc3"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://proxmox.server:8006/api2/json"
}

resource "proxmox_vm_qemu" "cirrustratus" {
  name        = "cirrustratus"
  target_node = "yellowsubmarine"
  memory      = "2048"
  cores       = "2"
  scsihw      = "virtio-scsi-single"
  
  network{
    bridge = "vmbr0"
    link_down = false
    firewall = true
    model = "virtio"
  }

  disks {
    ide {
      ide0 {
        cdrom {
          iso = "local:iso/nixos-24.05.20240630.7dca152-x86_64-linux.iso"
        }
      }
    }

    scsi {
      scsi0 {
        disk {
          size = "10G"
          storage = "local-lvm"
          iothread = true
        }
      }
      scsi1 {
        disk {
            size = "1T"
            storage = "zfs1"
            iothread = true
        }
      }
    }
  }
}
