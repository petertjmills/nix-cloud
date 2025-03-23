{ lib, config, ... }:
{
  options.monitoring = {
    prometheusScrapeConfigs = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            job_name = lib.mkOption {
              type = lib.types.str;
              default = "prometheus";
              description = "The job name to use in the scrape config";
            };

            metrics_path = lib.mkOption {
              type = lib.types.str;
              default = "/metrics";
              description = "The metrics path to use in the scrape config";
            };

            scheme = lib.mkOption {
              type = lib.types.str;
              default = "http";
              description = "The scheme to use in the scrape config";
            };

            static_configs = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    targets = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      description = "The list of targets to scrape";
                    };

                    labels = lib.mkOption {
                      type = lib.types.attrs;
                      default = { };
                      description = "The labels to add to the scrape config";
                    };
                  };
                }
              );
              default = [ ];
              description = "The list of static configs to use in the scrape config";
            };

            tls_config = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "The tls config to use in the scrape config";
            };
          };
        }
      );
      default = [ ];
    };
  };

  config = {

    services.prometheus.exporters.node = {
      enable = true;
      port = 9100;
      openFirewall = true;
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
      enabledCollectors = [ "systemd" ];
      # /nix/store/zgsw0yx18v10xa58psanfabmg95nl2bb-node_exporter-1.8.1/bin/node_exporter  --help
      extraFlags = [
        "--collector.ethtool"
        "--collector.softirqs"
        "--collector.tcpstat"
        "--collector.wifi"
      ];
    };

    monitoring.prometheusScrapeConfigs = [
      {
        job_name = "${config.networking.hostName}-node-exporter";
        static_configs = [
          {
            targets = [
              "${config.networking.hostName}.internal:9100"
            ];
          }
        ];
      }
    ];
  };
}
