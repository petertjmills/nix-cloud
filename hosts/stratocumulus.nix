{ config, ipPool, ... }:
let
  ip = ipPool 2;
in
{
  imports = [
    ../machines/incus-container.nix
    ../modules/dns.nix
  ];
  ip = ip.internalIp;
  lanIp = ip.address;
  networking.hostName = "stratocumulus";

  dns.server = true;

}
