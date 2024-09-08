{ modulesPath
, config
, lib
, pkgs
, ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./disk-config.nix
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.initrd.availableKernelModules = [ "virtio_scsi" ];
  boot.kernelParams = [ "boot.shell_on_fail" ];

  boot.loader.grub.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "cirrus"; # Define your hostname.
  networking.networkmanager.enable = true;

  age.secrets.cirrus_wireguard_private_key.file = ../../secrets/cirrus_wireguard_private_key.age;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  services.unbound = {
    enable = true;
    settings.server = {
      interface = [
        "0.0.0.0"
      ];

      access-control = [ "10.0.0.0/24 allow" ];

      local-zone = "\"e-clare.com.\" static";
      local-data = [
        "\"jellyfin.e-clare.com. IN A 192.168.86.225\""
        "\"text.e-clare.com. IN TXT 'this is a test'\""
      ];
    };
  };

  # Wireguard Config
  networking.nat.enable = true;
  networking.nat.externalInterface = "ens18";
  networking.nat.internalInterfaces = [ "wg0" "wg1" ];

  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ "10.0.0.1/24" ];

      # The port that WireGuard listens to. Must be accessible by the client.
      listenPort = 51820;

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
      postSetup = ''
        ${pkgs.iptables}/bin/iptables --append FORWARD --in-interface wg0 --jump ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat --append POSTROUTING --source 10.0.0.1/24 --out-interface ens18 --jump MASQUERADE
      '';

      # This undoes the above command
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables --delete FORWARD --in-interface wg0 --jump ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat --delete POSTROUTING --source 10.0.0.1/24 --out-interface ens18 --jump MASQUERADE
      '';

      # Path to the private key file.
      #
      # Note: The private key can also be included inline via the privateKey option,
      # but this makes the private key world-readable; thus, using privateKeyFile is
      # recommended.
      privateKeyFile = config.age.secrets.cirrus_wireguard_private_key.path;

      peers = [
        # List of allowed peers.
        {
          # Feel free to give a meaning full name
          # Public key of the peer (not a file path).
          publicKey = "cCGzVYGwHv7l6gBiC3IQrQJhrF5U9gVciRgCuTtDjEI=";
          # List of IPs assigned to this peer within the tunnel subnet. Used to configure routing.
          allowedIPs = [ "10.0.0.2/32" ];
        }

        {
          publicKey = "xtoo1P3JB2lg7e+la/gFnGXgMpqqEsCfqdfCM/AxlnQ=";
          allowedIPs = [ "10.0.0.3/32" ];
        }
      ];
    };
    wg1 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ "10.100.0.2/24" ];

      # The port that WireGuard listens to. Must be accessible by the client.
      listenPort = 9696;

      privateKeyFile = config.age.secrets.cirrus_wireguard_private_key.path;

      postSetup = ''
        ${pkgs.iptables}/bin/iptables --append FORWARD --in-interface wg1 --jump ACCEPT
        ${pkgs.iptables}/bin/iptables --append FORWARD --out-interface wg1 --jump ACCEPT
      '';

      postShutdown = ''
        ${pkgs.iptables}/bin/iptables --delete FORWARD --in-interface wg1 --jump ACCEPT
        ${pkgs.iptables}/bin/iptables --delete FORWARD --out-interface wg1 --jump ACCEPT
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

  time.timeZone = "Europe/London";

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    neofetch
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;



  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      53
    ];
    allowedUDPPorts = [
      53
      51820
      9696
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8tQOhDkrQO4q3W7JdernvtL1v+aiNsjozN41qrfs2n Silversurfer"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyxwQIShLIk/qHVnEkRWC+7/V82brDH3s0tBwpnttVi macmini"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPEhVfbVbix9lPz1+hQAeo7qRtQwIs6+ev22HLa4IiI+ root@cumulus"
  ];

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?

}
