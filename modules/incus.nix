{
  pkgs,
  inputs,
  ip,
  defaultGateway,
  hostname,
  ...
}:
let
in
# This produces a list of commands to import the images into incus
# The images come from flake vms
{

  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      8443
      53
      67
    ];
    allowedUDPPorts = [
      53
      67
    ];
  };
  # networking.firewall.trustedInterfaces = [ "incusbr0" ];
  networking.bridges = {
    "br0" = {
      interfaces = [ "enp1s0" ];
    };
  };
  networking.interfaces.br0.ipv4.addresses = [
    {
      address = ip.address;
      prefixLength = 24;
    }
  ];
  networking.useDHCP = false;
  networking.defaultGateway = defaultGateway;
  networking.hostName = hostname;
  networking.nameservers = [ "8.8.8.8" ];

  services.lvm.boot.thin.enable = true;
  services.lvm.enable = true;

  virtualisation.incus = {
    enable = true;
    package = pkgs.incus;
    ui.enable = true;
    preseed = {
      config."core.https_address" = "[::]:8443";
      config."images.auto_update_interval" = "0";
      networks = [
        # {
        #   name = "incusbr0";
        #   type = "bridge";
        #   config = {
        #     "ipv4.address" = "192.168.86.192/32";
        #   };
        # }
      ];
      storage_pools = [
        {
          name = "lvm";
          driver = "lvm";
          config = {
            size = "800GiB";
          };
        }
        # Only run this once. if it fails use incus storage
        # {
        #   config.source = "tank";
        #   name = "incus_zfs_pool";
        #   driver = "zfs";
        # }
      ];
      profiles = [
        {
          config."agent.nic_config" = true;
          devices.enp1s0 = {
            name = "enp1s0";
            nictype = "bridged";
            parent = "br0";
            type = "nic";
          };
          devices.root = {
            path = "/";
            pool = "lvm";
            type = "disk";
          };
          name = "default";
        }
      ];
    };
  };

  # systemd.services.incus_image_import_vms = {
  #   description = "After incus service starts, build nix images";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "incus.service" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #   };
  #   script = builtins.concatStringsSep "\n" vmImages;
  # };

  # This creates a service for each core vm that:
  #   - Deletes the image from incus
  #   - Imports the image into incus
  #   - Creates a vm from the image
  #   - ~~and starts it~~ Doesn't start the files because order can't be controlled this way.
  # systemd.services = pkgs.lib.mapAttrs' (
  #   vmName: vmValue:
  #   pkgs.lib.nameValuePair (vmName + "-image-service") {
  #     description = "After incus service starts, build ${vmName} image and try to reapply";
  #     wantedBy = [ "multi-user.target" ];
  #     after = [ "incus.service" ];
  #     serviceConfig = {
  #       Type = "oneshot";
  #     };

  #     script = ''
  #       ${pkgs.incus}/bin/incus image delete ${vmName} || true
  #       ${pkgs.incus}/bin/incus image import --alias ${vmName} ${vmValue.config.system.build.metadata}/tarball/nixos-system-x86_64-linux.tar.xz ${vmValue.config.system.build.qemuImage}/nixos.qcow2 --reuse --verbose
  #       ${pkgs.incus}/bin/incus create ${vmName} ${vmName} < ${
  #         toString (
  #           pkgs.writers.writeText "${vmName}config" (
  #             pkgs.lib.generators.toYAML { } inputs.self.core-vms.${vmName}._module.specialArgs.vm-config
  #           )
  #         )
  #       } || true
  #     '';
  #   }
  # ) inputs.self.core-vms;

  # TODO: Start core VMs

}
