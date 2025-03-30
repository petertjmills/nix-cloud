{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    ../machines/hetzner.nix
    inputs.sops-nix.nixosModules.sops
  ];

  ip = "167.235.63.14";

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  sops.defaultSopsFile = ../secrets/wireguard.yaml;
  sops.age.sshKeyPaths = [ "/root/.ssh/id_ed25519" ];
  sops.age.generateKey = true;

  sops.secrets."${config.networking.hostName}/private_key" = { };
  sops.secrets."${config.networking.hostName}/public_key" = { };

  networking.hostName = "cirrus";
  networking.nat.enable = true;
  networking.nat.externalInterface = "enp1s0";
  networking.nat.internalInterfaces = [ "wg0" ];

  networking.wireguard.interfaces = {
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ "10.100.0.1/24" ];
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
          publicKey = "Cb9V8hbU3aN5aWeI0KfdDDMH1HcdSkQ3YAeFX4y41zc=";
          allowedIPs = [
            "10.100.0.2/32"
            "10.0.0.0/8"
          ];
        }
        {
          # peters iphone
          publicKey = "ySrXo34ZWoLkUygaFCdYhA4YNRJsQ+/503s6x+QaBSE=";
          allowedIPs = [
            "10.100.0.3/32"
          ];
        }
        {
          # peters laptop
          publicKey = "izKoBqDZ/zihuiGZYQ0hqnYWi+xOr0SPuD/sVPf4BiE=";
          allowedIPs = [
            "10.100.0.4/32"
          ];
        }
        {
          # macmini
          publicKey = "YJokfOz2sw+4h6kSrBrWBTuReQOm2SlTOqDSgordfDU=";
          allowedIPs = [
            "10.100.0.5/32"
          ];
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
