{ modulesPath, pkgs, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/incus-virtual-machine.nix"
  ];

  services.resolved.enable = false;
  networking.useDHCP = true;
  networking.interfaces.enp1s0.ipv4.routes = [
    {
      address = "0.0.0.0";
      prefixLength = 0;
      via = "169.254.0.1";
      options.onlink = "";
    }
  ];

  # services.cloud-init.enable = true;
  # services.cloud-init.network.enable = true;
  # services.cloud-init.extraPackages = with pkgs; [
  # netplan
  # ];

  virtualisation.incus.agent.enable = true;
  virtualisation.incus.package = pkgs.incus;
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../secrets/public-keys/master_id_ed25519.pub
    ../secrets/public-keys/cumulus_id_ed25519.pub
    ../secrets/public-keys/sky_id_ed25519.pub
  ];

  nixpkgs.system = "x86_64-linux";
  system.stateVersion = "24.11";

  environment.systemPackages = [
    # pkgs.netplan # cloud-init network config does not support `on-link` routes, but will use netplan if it is available
    # However it still doesn't work :( Should find a solution in the future. Cloud init can't find libnetplan?
    # journalctl | grep netplan
    # Feb 24 20:03:54 nimbostratus cloud-init[692]: 2025-02-24 20:03:54,684 - schema.py[DEBUG]: Skipping netplan schema validation. No netplan API available
  ];
}
