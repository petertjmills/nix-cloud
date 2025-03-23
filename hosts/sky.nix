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
    ../modules/incus-server.nix
    ../modules/dns.nix
    ../modules/monitoring.nix
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

  services.incusServer = {
    enable = true;
    ip.address = ip.address;
    ip.internalSubnet = ip.internalSubnet;
    defaultGateway = ip.defaultGateway;
    images = [
      {
        name = "nixos-vm-base";
        module = ../images/incus-vm-base.nix;
        script = buildOutput: ''
            echo "Deleting old image"
          ${pkgs.incus}/bin/incus image delete ${buildOutput.name}

            echo "Importing new image"
          ${pkgs.incus}/bin/incus image import --alias ${buildOutput.name} \
            ${buildOutput.build.metadata}/tarball/nixos-system-x86_64-linux.tar.xz \
            ${buildOutput.build.qemuImage}/nixos.qcow2
        '';
      }
      {
        name = "nixos-lxc-base";
        module = ../images/incus-lxc-base.nix;
        script = buildOutput: ''
          echo "Deleting old image"
          ${pkgs.incus}/bin/incus image delete ${buildOutput.name}

          echo "Importing new image"
          ${pkgs.incus}/bin/incus image import --alias ${buildOutput.name} \
            ${buildOutput.build.metadata}/tarball/nixos-system-x86_64-linux.tar.xz \
            ${buildOutput.build.squashfs}/nixos-lxc-image-x86_64-linux.squashfs
        '';
      }
    ];
  };
}
