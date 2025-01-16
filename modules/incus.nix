{
  pkgs,
  inputs,
  ip,
  defaultGateway,
  hostname,
  ...
}:
let
  # This produces a list of commands to import the images into incus
  # The images come from flake vms
  vmImages = builtins.map (
    name:
    let
      value = inputs.self.vms.${name};
    in
    ''
      ${pkgs.incus}/bin/incus image delete ${name}
      ${pkgs.incus}/bin/incus image import --alias ${name} ${value.config.system.build.metadata}/tarball/nixos-system-x86_64-linux.tar.xz ${value.config.system.build.qemuImage}/nixos.qcow2 --reuse --verbose
    ''
  ) (builtins.attrNames inputs.self.vms);
in
{
  

  networking.nftables.enable = true;
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
  virtualisation.incus = {
    enable = true;
    ui.enable = true;
    preseed = {
      config."core.https_address" = "[::]:8443";
      config."images.auto_update_interval" = "0";
      networks = [ ];
      storage_pools = [
        # Only run this once. if it fails use incus storage
        # {
        #   config.source = "tank";
        #   name = "incus_zfs_pool";
        #   driver = "zfs";
        # }
      ];
      profiles = [
        {
          devices.enp1s0 = {
            name = "enp1s0";
            nictype = "bridged";
            parent = "br0";
            type = "nic";
          };
          devices.root = {
            path = "/";
            pool = "incus_zfs";
            type = "disk";
          };
          name = "default";
        }
      ];
    };
  };

  systemd.services.incus_image_import_vms = {
    description = "After incus service starts, build nix images";
    wantedBy = [ "multi-user.target" ];
    after = [ "incus.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = builtins.concatStringsSep "\n" vmImages;
    };
  };

}
