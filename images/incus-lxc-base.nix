{ modulesPath, pkgs, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    # This
    "${modulesPath}/virtualisation/incus-agent.nix"
  ];

  services.resolved.enable = false;
  networking.useDHCP = false;

  virtualisation.incus.agent.enable = true;
  virtualisation.incus.package = pkgs.incus;
  services.cloud-init = {
    enable = true;
    network.enable = true;
  };
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../secrets/public-keys/master_id_ed25519.pub
    ../secrets/public-keys/cumulus_id_ed25519.pub
    ../secrets/public-keys/sky_id_ed25519.pub
  ];

  nixpkgs.system = "x86_64-linux";
  system.stateVersion = "24.11";
}
