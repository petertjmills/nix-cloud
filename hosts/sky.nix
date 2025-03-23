{
  pkgs,
  ipPool,
  config,
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
