{
  config,
  pkgs,
  lib,
  ipPool,
  inputs,
  ...
}:
let
  ip = ipPool 3;
  scrapeConfigs = (
    pkgs.lib.attrsets.foldlAttrs (
      acc: name: value:
      acc
      ++ (
        if value.config ? monitoring.prometheusScrapeConfigs then
          value.config.monitoring.prometheusScrapeConfigs
        else
          [ ]
      )
    ) [ ] inputs.self.nixosConfigurations
  );
in
{
  imports = [
    ../machines/incus-container.nix
  ];

  networking.hostName = "stratus";
  ip = ip.internalIp;
  lanIp = ip.address;

  networking.firewall = {
    allowedTCPPorts = [
      config.services.prometheus.port
    ];
  };

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s"; # "1m"
    scrapeConfigs = scrapeConfigs;
  };
}
