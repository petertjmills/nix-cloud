{
  lib,
  pkgs,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  networking.networkmanager.enable = true;
  environment.systemPackages = [
    pkgs.neofetch
    pkgs.git
    pkgs.just
    pkgs.cryptsetup
  ];
  time.timeZone = "Europe/London";
  #TODO: Move this to ssh.nix
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8tQOhDkrQO4q3W7JdernvtL1v+aiNsjozN41qrfs2n Silversurfer"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyxwQIShLIk/qHVnEkRWC+7/V82brDH3s0tBwpnttVi macmini"
  ];
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../secrets/public-keys/master_id_ed25519.pub
    ../secrets/public-keys/cumulus_id_ed25519.pub
  ];
  system.stateVersion = "24.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
