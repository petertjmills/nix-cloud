{
  pkgs,
  config,
  hostname,
  ...
}:
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  sops.defaultSopsFile = ../secrets/wireguard.yaml;
  sops.age.sshKeyPaths = [ "/root/.ssh/id_ed25519" ];
  sops.age.generateKey = true;

  sops.secrets."${hostname}/private_key" = { };
  sops.secrets."${hostname}/public_key" = { };

  networking.nat.enable = true;
  networking.nat.externalInterface = "enp1s0";
  networking.nat.internalInterfaces = [ "wg0" ];

  networking.wireguard.interfaces = {
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ "10.100.0.2/24" ];
      privateKeyFile = config.sops.secrets."${hostname}/private_key".path;

      # The port that WireGuard listens to. Must be accessible by the client.
      listenPort = 9696;

      mtu = 1420-8;

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
          publicKey = "H+RLWriegaZZTb+bb1FiugcxAOwFsJ7pIrYnBPMKDS4=";
          allowedIPs = [ "10.100.0.0/24" ];
          endpoint = "167.235.63.14:51820";
          persistentKeepalive = 10;
        }
      ];
    };
  };

  networking.firewall = {
    allowedUDPPorts = [
      9696
    ];
  };
}
