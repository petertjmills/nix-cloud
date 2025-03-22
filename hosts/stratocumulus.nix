{ ... }:
{
  imports = [
    ../machines/incus-container.nix
    ../modules/dns.nix
  ];

  networking.hostName = "stratocumulus";
}
