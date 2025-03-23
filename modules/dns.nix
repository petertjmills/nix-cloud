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
        interface = [
          "0.0.0.0"
        ];

        access-control = [ "192.168.86.0/24 allow" ];

        # Not sure if this will conflict with host dns settings
        private-address = [
          ''"10.0.0.0/8"''
          ''"172.16.0.0/12"''
          ''"192.168.0.0/16"''
          ''"169.254.0.0/16"''
          ''"fd00::/8"''
          ''"fe80::/10"''
          ''"::ffff:0:0/96"''
        ];

        local-zone = ''"e-clare.com." static'';
        local-data = builtins.map (host: ''"${host.name}. IN A ${host.ip}"'') hosts;
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
