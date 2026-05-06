{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.dns;
  unboundWithDoH = pkgs.unbound-with-systemd.override {
    withDoH = true;
  };
in
{
  imports = [
    # ./monitoring.nix
  ];

  options.local.dns = {
    server = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    records = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              default = "e-clare.com";
            };
            data = lib.mkOption {
              type = lib.types.str;
              default = "";
            };
            type = lib.mkOption {
              type = lib.types.str;
              default = "";
            };
          };
        }
      );
      default = [ ];
    };
  };

  config = lib.mkIf cfg.server {
    services.unbound = {
      enable = true;
      package = unboundWithDoH;
      resolveLocalQueries = true;
      settings = {
        server = {
          interface = [
            "0.0.0.0"
            "0.0.0.0@8443"
          ];
          https-port = 8443;
          tls-service-key = "${config.security.acme.certs."wildcard.ts.pm4.uk".directory}/key.pem";
          tls-service-pem = "${config.security.acme.certs."wildcard.ts.pm4.uk".directory}/cert.pem";
          access-control = [
            "192.168.86.0/24 allow"
            "10.0.0.0/8 allow"
            "100.64.0.0/10 allow"
          ];

          local-data = builtins.map (r: ''"${r.name} IN ${r.type} ${r.data}"'') cfg.records;
        };

        forward-zone = {
          name = ''"."'';
          forward-tls-upstream = true;
          forward-addr = [
            ''"1.1.1.1@853#cloudflare-dns.com"''
            ''"9.9.9.9@853#dns.quad9.net"''
          ];
        };

        remote-control.control-enable = true;
      };
    };
    users.users.unbound.extraGroups = [ "acme" ];

    # services.prometheus.exporters.unbound = {
    #   enable = true;
    #   port = 9101;
    #   openFirewall = true;
    # };

    # monitoring.prometheusScrapeConfigs = [
    #   {
    #     job_name = "unbound";
    #     static_configs = [
    #       {
    #         targets = [
    #           "${config.networking.hostName}.internal:9101"
    #         ];
    #       }
    #     ];
    #   }
    # ];

  };
}
