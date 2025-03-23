{
  config,
  pkgs,
  lib,
  ipPool,
  ...
}:
let
  ip = ipPool 1;
in
{
  imports = [
    ../machines/incus-container.nix
    ../modules/zsh.nix
    ../modules/opentofu.nix
  ];

  networking.hostName = "cumulus";
  ip = ip.internalIp;
  lanIp = ip.address;

  terranix.resource."incus_instance"."${config.networking.hostName}" = {
    config."security.nesting" = true;
    limits = {
      cpu = 2;
      memory = "4GiB";
    };
    device = [
      {
        name = "root";
        type = "disk";
        properties = {
          path = "/";
          pool = "lvm";
          size = "50GiB";
        };
      }
    ];
  };

  environment.systemPackages = [
    pkgs.nixd
    pkgs.nixfmt-rfc-style
    pkgs.incus
    pkgs.git
    pkgs.just
  ];
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
