{ inputs, ... }:
let
  hosts = { };
in
{
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
      local-data = [
        ''"text.e-clare.com. IN TXT 'this is a dns text record'" ''
        ''"google-redirect.e-clare.com. IN A 142.250.200.46"''
      ];

    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
}
