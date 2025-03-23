{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.incusServer;

  # Helper function to create images
  mkImage =
    {
      name,
      module,
      ...
    }:
    rec {
      inherit name;
      nixosConfig = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          module
        ];
      };
      build = nixosConfig.config.system.build;

    };

  ips = (
    lib.attrsets.foldlAttrs (
      acc: name: value:
      acc
      ++ (
        if value.config ? lanIp then
          [
            {
              address = value.config.lanIp;
              prefixLength = 24;
            }
          ]
        else
          [ ]
      )
    ) [ ] inputs.self.nixosConfigurations
  );
in
{
  options.services.incusServer = {
    enable = mkEnableOption "Incus container server";

    ip = mkOption {
      type = types.submodule {
        options = {
          address = mkOption {
            type = types.str;
            description = "IP address for the bridge interface";
            example = "192.168.1.10";
          };

          internalSubnet = mkOption {
            type = types.str;
            description = "Internal subnet for incus containers/VMs";
            example = "10.0.0.1/24";
            default = "10.0.0.1/24";
          };
        };
      };
      description = "Network IP configuration";
    };

    defaultGateway = mkOption {
      type = types.str;
      description = "Default gateway address";
      example = "192.168.1.1";
    };

    bridgeInterface = mkOption {
      type = types.str;
      description = "Physical interface to bridge";
      default = "enp1s0";
      example = "eth0";
    };

    bridgeName = mkOption {
      type = types.str;
      description = "Name of the bridge interface";
      default = "br0";
    };

    internalBridgeName = mkOption {
      type = types.str;
      description = "Name of the incus internal bridge";
      default = "incusbr0";
    };

    httpPort = mkOption {
      type = types.port;
      description = "Port for the HTTP interface";
      default = 8443;
    };

    dhcpEnabled = mkOption {
      type = types.bool;
      description = "Whether to enable DHCP on the internal network";
      default = true;
    };

    natEnabled = mkOption {
      type = types.bool;
      description = "Whether to enable NAT on the internal network";
      default = true;
    };

    images = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Image name";
            };
            module = mkOption {
              type = types.path;
              description = "Path to the image module";
            };
            script = mkOption {
              type = types.anything;
              description = "Script to run to import the image";
            };
          };
        }
      );
      default = { };
      description = "Images to create";
    };
  };

  config = mkIf cfg.enable {
    networking.nftables.enable = true;

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        cfg.httpPort
        8444
        53
        67
      ];
      allowedUDPPorts = [
        53
        67
      ];
      trustedInterfaces = [ cfg.internalBridgeName ];
    };

    networking.bridges = {
      "${cfg.bridgeName}" = {
        interfaces = [ cfg.bridgeInterface ];
      };
    };

    networking.interfaces."${cfg.bridgeName}".ipv4 = {
      addresses = [
        {
          address = cfg.ip.address;
          prefixLength = 24;
        }
      ] ++ ips;
    };

    networking.defaultGateway = {
      address = cfg.defaultGateway;
      interface = cfg.bridgeName;
    };

    services.lvm.boot.thin.enable = true;
    services.lvm.enable = true;
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    virtualisation.incus = {
      enable = true;
      package = pkgs.incus;
      ui.enable = true;
      preseed = {
        config."core.https_address" = "[::]:${toString cfg.httpPort}";
        config."core.metrics_authentication" = false;
        config."images.auto_update_interval" = "0";
        networks = [
          {
            config = {
              "ipv4.address" = cfg.ip.internalSubnet;
              "ipv4.dhcp" = toString cfg.dhcpEnabled;
              "ipv4.nat" = toString cfg.natEnabled;
            };
            name = cfg.internalBridgeName;
            type = "bridge";
          }
        ];
        storage_pools = [ ];
        profiles = [
          {
            config."agent.nic_config" = true;
            devices.root = {
              path = "/";
              pool = "lvm";
              type = "disk";
            };
            name = "default";
          }
        ];
      };
    };

    systemd.services = builtins.listToAttrs (
      map (
        image:
        let
          imageObj = mkImage image;
          serviceName = "incus-import-image-${image.name}";
          importScript = image.script imageObj;
        in
        {
          name = serviceName;
          value = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = pkgs.writers.writeBash "import-script" "${importScript}";
            };
            description = "Import Incus image ${image.name}";
          };
        }
      ) cfg.images
    );
  };
}
