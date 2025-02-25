{
  nixpkgs,
  inputs,
  defaultGateway,
  ...
}:
{
  name,
  ip,
  terranix ? null,
  modules ? null,
}:
nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs defaultGateway;

    ip = ip;
    hostname = name;

    terranix =
      if terranix == null then
        null
      else
        {
          resource."incus_instance"."${name}" = {
            name = name;
            image = terranix.image;
            type = if terranix.image == "nixos-lxc-base" then "container" else "virtual-machine";
            config = terranix.config;
            # For vm's we use cloud-init to configure the network.
            # if terranix.image == "nixos-vm-base" then
            #   terranix.config
            #   // {
            #     "cloud-init.network-config" = ''
            #       network:
            #             version: 2
            #             ethernets:
            #               enp1s0:
            #                 addresses:
            #                 - ${ip.address}/32
            #                 nameservers:
            #                   addresses:
            #                   - 8.8.8.8
            #                   - ${inputs.self.nixosConfigurations.stratocumulus._module.specialArgs.ip.address}
            #     '';
            #     # on-link above doesn't work because cloud-init can't see netplan, so doesn't use it
            #     # "cloud-init.user-data" = ''
            #     #   #cloud-config
            #     #       runcmd:
            #     #         - [ip, r, a, default, via, 169.254.0.1, dev, enp1s0, onlink]
            #     # '';
            #   }
            # else
            #   terranix.config;
            device = (if terranix ? device then terranix.device else [ ]) ++ [
              {
                name = "enp1s0";
                type = "nic";
                properties = {
                  "ipv4.address" = ip.address;
                  # "ipv4.gateway" = defaultGateway;
                  # "ipv4.dhcp" = false;
                  parent = "enp1s0";
                  nictype = "routed";
                  name = "enp1s0";
                };
              }
            ];
            # provisioner =
            #   if terranix.image == "nixos-vm-base" then
            #     {
            #       "local-exec" = {
            #         command = ''
            #           incus exec ${name} ip addr add ${ip.address}/32 dev enp1s0 && \
            #           incus exec ${name} ip route add default via 169.254.0.1 dev enp1s0 onlink"
            #         '';
            #       };
            #     }
            #   else
            #     null;

          };

          import = [
            # {
            #   to = "incus_instance.${name}";
            #   id = "${name},image=${terranix.image}";
            # }
          ];
        };

  };

  modules = [
    inputs.sops-nix.nixosModules.sops
    ../modules
    ../modules/networking.nix
    {
      networking.hostName = name;
    }
  ] ++ modules;
}
