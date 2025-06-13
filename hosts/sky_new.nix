{
  pkgs,
  ipPool,
  config,
  inputs,
  ...
}:
let
  ip = ipPool 0;
in
{
  imports = [
    ../machines/home-server.nix
    ../modules/zsh.nix
    ../modules/dns.nix
    ../modules/monitoring.nix
    ../modules/jellyfin.nix
  ];

  ip = ip.internalIp;

  networking.hostName = "sky";
  dns.domains = [
    {
      name = "${config.networking.hostName}.internal";
      ip = ip.internalIp;
    }
    {
      name = "${config.networking.hostName}.lan";
      ip = ip.address;
    }
  ];

  monitoring.prometheusScrapeConfigs = [
    {
      job_name = "incus";
      metrics_path = "/1.0/metrics";
      static_configs = [
        {
          targets = [
            "${config.networking.hostName}.internal:8443"
          ];
        }
      ];
      scheme = "https";
      tls_config = {
        insecure_skip_verify = true;
      };
    }
    {
      job_name = "seaweedfs";
      static_configs = [
        {
          targets = [
            "${config.networking.hostName}.internal:29333"
            "${config.networking.hostName}.internal:28080"
            "${config.networking.hostName}.internal:28081"
            "${config.networking.hostName}.internal:28888"
            "${config.networking.hostName}.internal:28333"
          ];
        }
      ];
    }
  ];
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

  services.seaweedfs = {
    enable = true;
    enableServer = true;
    package = pkgs.callPackage ../packages/seaweedfs.nix { };
  };

}
