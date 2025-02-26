{ pkgs, config, ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  networking.nat.enable = true;
  networking.nat.externalInterface = "enp1s0";
  networking.nat.internalInterfaces = [ "wg0" ];

  networking.wireguard.interfaces = {
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ "10.100.0.2/24" ];

      # The port that WireGuard listens to. Must be accessible by the client.
      listenPort = 9696;

      postSetup = ''
        ${pkgs.iptables}/bin/iptables --append FORWARD --in-interface wg0 --jump ACCEPT
        ${pkgs.iptables}/bin/iptables --append FORWARD --out-interface wg0 --jump ACCEPT
      '';

      postShutdown = ''
        ${pkgs.iptables}/bin/iptables --delete FORWARD --in-interface wg0 --jump ACCEPT
        ${pkgs.iptables}/bin/iptables --delete FORWARD --out-interface wg0 --jump ACCEPT
      '';

      peers = [
        {
          publicKey = "UgKxWdYS4MxE8uKW+7gJwHRtnwm7GhIVzY8N7SBYqnc=";
          allowedIPs = [ "10.100.0.0/24" ];
          endpoint = "162.55.216.236:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
