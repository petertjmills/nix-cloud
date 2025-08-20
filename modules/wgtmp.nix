  networking.wireguard.interfaces = {
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ "10.100.0.2/24" ];
      privateKeyFile = config.sops.secrets."${config.networking.hostName}/private_key".path;

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
          publicKey = "H+RLWriegaZZTb+bb1FiugcxAOwFsJ7pIrYnBPMKDS4=";
          allowedIPs = [ "10.100.0.0/24" ];
          endpoint = "167.235.63.14:9696";
          persistentKeepalive = 25;
        }
        {
          # peters iphone
          publicKey = "ySrXo34ZWoLkUygaFCdYhA4YNRJsQ+/503s6x+QaBSE=";
          allowedIPs = [
            "10.100.0.6/32"
          ];
        }
        {
          # peters laptop
          publicKey = "izKoBqDZ/zihuiGZYQ0hqnYWi+xOr0SPuD/sVPf4BiE=";
          allowedIPs = [
            "10.100.0.7/32"
          ];
        }
        {
          # macmini
          publicKey = "YJokfOz2sw+4h6kSrBrWBTuReQOm2SlTOqDSgordfDU=";
          allowedIPs = [
            "10.100.0.8/32"
          ];
        }
      ];
    };
  };
