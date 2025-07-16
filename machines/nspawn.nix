{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.channel.enable = false;
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8tQOhDkrQO4q3W7JdernvtL1v+aiNsjozN41qrfs2n Silversurfer"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyxwQIShLIk/qHVnEkRWC+7/V82brDH3s0tBwpnttVi macmini"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHJe5VFKWSvT9TPlnkK1euRaMxC7JDn0vqBQ/x5SIz6O root@sky"
  ];

  system.stateVersion = "24.05";

  time.timeZone = "Europe/London";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
