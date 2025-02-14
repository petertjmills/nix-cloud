{
  pkgs,
  ip,
  defaultGateway,
  hostname,
  inputs,
  ...
}:
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
  # networking.bridges = {
  # "br0" = {
  # interfaces = [ "enp1s0" ];
  # };
  # };

  services.lvm.boot.thin.enable = true;
  services.lvm.enable = true;
 boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  virtualisation.incus = {
    enable = true;
    package = pkgs.incus;
    ui.enable = true;
    preseed = {
      config."core.https_address" = "[::]:8443";
      config."images.auto_update_interval" = "0";
      networks = [ ];
      storage_pools = [

      ];
      profiles = [
        {
          config."agent.nic_config" = true;
          devices.enp1s0 = {
            name = "enp1s0";
            nictype = "routed";
            parent = "enp1s0";
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

  systemd.services.incus-import-images = let
      mkImage =
      { name, module }:
      rec {
        inherit name;
        nixosConfig = inputs.nixpkgs.lib.nixosSystem {
          modules = [
            module
          ];
        };
        build = nixosConfig.config.system.build;
      };

      images = {
        incus-lxc-base = mkImage {
          name = "nixos-lxc-base";
          module = ../images/incus-lxc-base.nix;
        };

        incus-vm-base = mkImage {
          name = "nixos-vm-base";
          module = ../images/incus-vm-base.nix;
        };
      };


  in {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writers.writeBash "destroy" ''
          echo "importing LXC image"
          ${pkgs.incus}/bin/incus image delete ${images.incus-lxc-base.name}
          ${pkgs.incus}/bin/incus image import --alias ${images.incus-lxc-base.name} \
            ${images.incus-lxc-base.build.metadata}/tarball/nixos-system-x86_64-linux.tar.xz \
            ${images.incus-lxc-base.build.squashfs}/nixos-lxc-image-x86_64-linux.squashfs

            echo "importing VM image"
          ${pkgs.incus}/bin/incus image delete ${images.incus-vm-base.name}
          ${pkgs.incus}/bin/incus image import --alias ${images.incus-vm-base.name} \
            ${images.incus-vm-base.build.metadata}/tarball/nixos-system-x86_64-linux.tar.xz \
            ${images.incus-vm-base.build.qemuImage}/nixos.qcow2
      '';
    };
  };

}
