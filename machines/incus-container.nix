{
  modulesPath,
  pkgs,
  inputs,
  config,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../modules/terranix.nix
  ];

  terranix.resource."incus_instance"."${config.networking.hostname}" = {
        name = "${config.networking.hostname}";
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
  };

  virtualisation.incus.agent.enable = true;
  virtualisation.incus.package = pkgs.incus;
  networking.interfaces.enp1s0.useDHCP = true;
}
