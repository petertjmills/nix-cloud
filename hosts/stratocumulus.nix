{ config, ipPool, ... }:
let
  ip = ipPool 2;
in
{
  imports = [
    ../machines/incus-container.nix
    ../modules/dns.nix
    ../modules/monitoring.nix
  ];
  ip = ip.internalIp;
  lanIp = ip.address;
  networking.hostName = "stratocumulus";

  dns.server = true;

  services.prometheus.exporters.unbound = {
    enable = true;
    port = 9101;
    openFirewall = true;
  };

  monitoring.prometheusScrapeConfigs = [
    {
      job_name = "unbound";
      static_configs = [
        {
          targets = [
            "${config.networking.hostName}.internal:9101"
          ];
        }
      ];
    }
  ];
}
