{
  inputs,
  lib,
  config,
  ...
}:
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

    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 9080;
          grpc_listen_port = 0;
        };

        clients = [
          {
            url = "http://${inputs.self.nixosConfigurations.stratus.config.ip}:3100/loki/api/v1/push";
          }
        ];

        scrape_configs = [
          {
            job_name = "${config.networking.hostName}-journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "${config.networking.hostName}-systemd-journal";
              };
            };
            relabel_configs = [
              {
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }
              {
                source_labels = [ "__journal__hostname" ];
                target_label = "hostname";
              }
              {
                source_labels = [ "__journal_priority_keyword" ];
                target_label = "severity";
              }
            ];
          }
        ];

      };
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
