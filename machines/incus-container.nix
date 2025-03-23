{
  modulesPath,
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
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

  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../modules/terranix.nix
  ];
  config = {
    terranix.resource = {
      "incus_instance"."${config.networking.hostName}" = {
        name = "${config.networking.hostName}";
        image = "nixos-lxc-base";
        config = {
          "boot.autostart" = true;
        };

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

    virtualisation.incus.agent.enable = true;
    virtualisation.incus.package = pkgs.incus;
    networking.interfaces.enp1s0.useDHCP = true;
    networking.nameservers = [
      "1.1.1.1"
    ];

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

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };

}
