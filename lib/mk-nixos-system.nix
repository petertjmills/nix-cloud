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
  type ? "incus_instance",
  system ? "x86_64-linux"
}:
nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs defaultGateway;

    ip = ip;
    hostname = name;

    terranix =
      if terranix == null then
        null
      else
        {
          resource."${type}"."${name}" = {
            name = name;
            image = terranix.image;
            type = if terranix.image == "nixos-lxc-base" then "container" else "virtual-machine";
            config = terranix.config;
            limits = if terranix ? limits then terranix.limits else { };
            device = (if terranix ? device then terranix.device else [ ]) ++ [
              {
                name = "enp1s0";
                type = "nic";
                properties = {
                  "ipv4.address" = ip.internalIp;
                  "ipv6.address" = null;
                  network = "incusbr0";
                  name = "enp1s0";
                };
              }
            ];
          };

          resource."incus_network_forward"."${name}_forward" = {
            network = "incusbr0";
            listen_address = ip.address;
            config.target_address = ip.internalIp;
            provisioner."local-exec" = {
              command = ''ssh root@192.168.86.192 "ip addr add ${ip.address}/24 dev br0"'';
            };
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
