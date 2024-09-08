terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
# variable "hcloud_token" {
#   sensitive = true
# }

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_server" "stratus" {
    name = "stratus"
    server_type = "cax11"
    image = "debian-12"
    location = "nbg1"

    ssh_keys = [
        "Silversurfer",
        "macmini",
        "root@cumulus"
    ]

    iso = "nixos-minimal-24.05.1503.752c634c09ce-aarch64-linux.iso"
}