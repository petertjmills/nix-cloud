{ modulesPath, pkgs, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/incus-virtual-machine.nix"
  ];

  networking.useDHCP = true;

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
