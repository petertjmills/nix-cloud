{
  modulesPath,
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/incus-virtual-machine.nix"
    ../modules/terranix.nix
    ../modules/monitoring.nix
    ../modules/dns.nix
  ];

  options.ip = lib.mkOption {
    type = lib.types.str;
    default = "";
    description = "The IP address of the container";
  };
  options.lanIp = lib.mkOption {
    type = lib.types.str;
    default = "";
    description = "The external LAN IP address of the container";
  };

  config = {
    terranix.resource = {
      "incus_instance"."${config.networking.hostName}" = {
        name = "${config.networking.hostName}";
        image = "nixos-vm-base";
        config = {
          "boot.autostart" = true;
        };
        limits = lib.mkDefault {
          cpu = 1;
          memory = "1GiB";
        };
        type = "virtual-machine";

        device = [
          {
            name = "enp1s0";
            type = "nic";
            properties = {
              "ipv4.address" = config.ip;
              "ipv6.address" = null;
              network = "incusbr0";
              name = "enp1s0";
            };
          }
        ];
      };
      "incus_network_forward"."${config.networking.hostName}" = {
        network = "incusbr0";
        listen_address = config.lanIp;
        config = {
          target_address = config.ip;
        };
      };
    };

    dns.domains = [
      {
        name = "${config.networking.hostName}.internal";
        ip = config.ip;
      }
      {
        name = "${config.networking.hostName}.lan";
        ip = config.lanIp;
      }
    ];

    virtualisation.incus.agent.enable = true;
    virtualisation.incus.package = pkgs.incus;
    networking.interfaces.enp1s0.useDHCP = true;
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
