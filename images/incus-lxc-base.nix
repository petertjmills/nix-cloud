{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  services.cloud-init.network.enable = true;
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../secrets/public-keys/master_id_ed25519.pub
    ../secrets/public-keys/cumulus_id_ed25519.pub
    ../secrets/public-keys/sky_id_ed25519.pub
  ];

  nixpkgs.system = "x86_64-linux";
  system.stateVersion = "24.11";
}
