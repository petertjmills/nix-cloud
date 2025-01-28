{ pkgs, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8tQOhDkrQO4q3W7JdernvtL1v+aiNsjozN41qrfs2n Silversurfer"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyxwQIShLIk/qHVnEkRWC+7/V82brDH3s0tBwpnttVi macmini"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPEhVfbVbix9lPz1+hQAeo7qRtQwIs6+ev22HLa4IiI+ root@cumulus"
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
