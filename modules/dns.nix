{
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.dns;
  hosts =
    (lib.attrsets.foldlAttrs (acc: name: value: {
      domains = acc.domains ++ (value.config.dns or { domains = [ ]; }).domains;
    }) { domains = [ ]; } inputs.self.nixosConfigurations).domains;
in
{
  imports = [
    ./monitoring.nix
  ];

  options.dns = {
    server = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    domains = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              default = "e-clare.com";
            };
            ip = lib.mkOption {
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
      resolveLocalQueries = true;
      settings = {
        server = {
          interface = [
            "0.0.0.0"
          ];

          access-control = [
            "192.168.86.0/24 allow"
            "10.0.0.0/8 allow"
          ];
          # private-address = [
          #   ''"10.0.0.0/8"''
          #   ''"172.16.0.0/12"''
          #   ''"192.168.0.0/16"''
          #   ''"169.254.0.0/16"''
          #   ''"fd00::/8"''
          #   ''"fe80::/10"''
          #   ''"::ffff:0:0/96"''
          # ];
          local-zone = "'youtube.com.' redirect";
          local-data = builtins.map (host: ''"${host.name}. IN A ${host.ip}"'') hosts ++ [
            ''"test.metachroma.co. IN A 10.0.0.2"''
            ''"test.metachroma.co. IN MX 10 test.metachroma.co."''
            "'_dmarc.metachroma.co. IN TXT \"v=DMARC1;p=reject;rua=mailto:dmarc@metachroma.co\"'"
            "'test.metachroma.co. IN TXT \"v=spf1 ip4:193.237.206.90 ~all\"'"
            # Youtube blackhole

            "'youtube.com. IN A 127.0.0.1'"

            # '''metachroma._domainkey.test IN TXT "p=MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAiwepiBaOQBPupaITjupdpZMzczkkRHdb9WVNxXIZSuAuvXhZl++QQrQDllmj2YquyyLly8/J/NW+vPO7G4PFlLgn5vmgREDnM6sUfTCcA0ALgDD3DUnusOKOYlUvJ36nJlM43dsSFD/bkULQvTXNVMVIa/s9Er+LaDf2DRjrxVIrottbU6/KQHHeeKrgYxHxBIdr6Yi8pCaIdjuIOuPH2ZhmYw33xDY/i/lFUygH2NgZH5l0Yv4CM/3GjW9LKNRlygAqHTyUXo1f3LNA5yCt7CBoZo8ctnrBj+dOVJWaTQWj2fj/sQrVBA7cGmVZDrNNzEbDUnLh3V1zgdRFQ2QzLZt4IYGzLRu99PyeKQJYmifTPfgrcQK13/T+VcqfCxhF0q7AdiUwo8rB4kDoTyITxqNM7aje6ox85VFpsDsR2SKXinFgwXTuViPOfwxCRNpBiiv/8qPH3VteZiq7LP0tQFObEIihKGzpj+NGVXfIOfWNpSycH94XsPtUFW+BNtUNeDx4tlTOlScl7VlXeS8g9hy9bxDtmNwy3h3p2BKpUH7myCuSyWalunnUzh9LThrYyNvjfQFxyQbsCoRqHCSH+gDkpFgi8viNIlmlTTkYQ4D3hMhsPlQtCsB8rVgKRDBDE/0ET0YktAN//BWvBwghXm6P3eYbzLdpPRLQyQP/8TcCAwEAAQ=="' ''
          ];
        };

        forward-zone = {
          name = ''"."'';
          forward-tls-upstream = true;
          forward-addr = ''"1.1.1.1@853#cloudflare-dns.com"'';

        };

        remote-control.control-enable = true;
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };

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

  };
}
