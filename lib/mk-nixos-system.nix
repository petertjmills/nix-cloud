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
            config = terranix.config;
            device = (if terranix ? device then
              terranix.device else [])  ++ [
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

          };
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
