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
      config.services.loki.configuration.server.http_listen_port
      config.services.grafana.settings.server.http_port
    ];
  };

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s"; # "1m"
    scrapeConfigs = scrapeConfigs;
  };

  environment.etc."grafana/dashboards/incus-dashboard.json".source =
    ../configs/grafana/incus-dashboard.json;
  environment.etc."grafana/dashboards/seaweedfs-dashboard.json".source =
    ../configs/grafana/seaweedfs-dashboard.json;

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        http_addr = "0.0.0.0";
      };
    };
    provision = {
      enable = true;

      dashboards.settings = {
        apiVersion = 1;

        providers = [
          {
            name = "default";
            options.path = "/etc/grafana/dashboards";
          }
        ];
      };
    };
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_address = "0.0.0.0";
        http_listen_port = 3100;
      };

      common = {
        ring.instance_addr = "127.0.0.1";
        ring.kvstore.store = "inmemory";
        replication_factor = 1;
        path_prefix = "/tmp/loki";
      };

      schema_config.configs = [
        {
          from = "2020-05-15";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      storage_config.filesystem.directory = "/tmp/loki/chunks";

    };
  };
}
