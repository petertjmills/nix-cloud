{
  nixpkgs,
  inputs,
  defaultGateway,
  self,
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
            config = terranix.config // {
              "cloud-init.network-config" = ''
                version: 2
                ethernets:
                  enp1s0:
                    dhcp4: no
                    addresses:
                      - ${ip.address}/24
                    gateway4: ${defaultGateway}
                    nameservers:
                      addresses:
                        - ${self.nixosConfigurations.stratocumulus._module.specialArgs.ip.address}
              '';

            };
            device = terranix.device;
          };
        };

  };

  modules = [
    inputs.sops-nix.nixosModules.sops
    ../modules
    {
      networking.hostName = name;
    }
  ] ++ modules;
}
