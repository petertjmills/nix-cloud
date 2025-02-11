{ modulesPath
, config
, lib
, pkgs
, ...
}:

{
  imports = [
    ./disk-config.nix
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ ];

  boot.loader.grub.enable = true;
  # Required for Hetzner UEFI boot.
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.grub.device = "/dev/sda";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "stratus"; # Define your hostname.
  networking.networkmanager.enable = true;

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
    ];
    allowedUDPPorts = [
      51820
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8tQOhDkrQO4q3W7JdernvtL1v+aiNsjozN41qrfs2n Silversurfer"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyxwQIShLIk/qHVnEkRWC+7/V82brDH3s0tBwpnttVi macmini"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPEhVfbVbix9lPz1+hQAeo7qRtQwIs6+ev22HLa4IiI+ root@cumulus"
  ];

  age.secrets.stratus_wireguard_private_key.file = ../../secrets/stratus_wireguard_private_key.age;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  # Wireguard Config
  networking.nat.enable = true;
  networking.nat.externalInterface = "enp1s0";
  networking.nat.internalInterfaces = [ "wg0" ];

  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ "10.100.0.1/24" ];

      # The port that WireGuard listens to. Must be accessible by the client.
      listenPort = 51820;

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
      postSetup = ''
        ${pkgs.iptables}/bin/iptables --append FORWARD --in-interface wg0 --jump ACCEPT
        ${pkgs.iptables}/bin/iptables --append FORWARD --out-interface wg0 --jump ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat --append POSTROUTING --source 10.100.0.1/24 --out-interface enp1s0 --jump MASQUERADE
      '';

      # This undoes the above command
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables --delete FORWARD --in-interface wg0 --jump ACCEPT
        ${pkgs.iptables}/bin/iptables --delete FORWARD --out-interface wg0 --jump ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat --delete POSTROUTING --source 10.100.0.1/24 --out-interface enp1s0 --jump MASQUERADE
      '';

      privateKeyFile = config.age.secrets.stratus_wireguard_private_key.path;

      peers = [
        {
          publicKey = "a3l8yQluObIOydp6qpdSTv8CKSEEtCUb7A5ggsAfBFw=";
          allowedIPs = [ "10.100.0.2/32" "192.168.86.0/24" ];
        }
        {
          publicKey = "/ANlH9RU1OV+Sa53pXEwgBRJd/0XE5qZLeIcqoT3qAk=";
          allowedIPs = [ "10.100.0.3/32" ];
        }
        {
          publicKey = "cCGzVYGwHv7l6gBiC3IQrQJhrF5U9gVciRgCuTtDjEI=";
          allowedIPs = [ "10.100.0.4/32" ];
        }
        {
          publicKey = "mxkPIIq1tb3XIYoOUxf2nZad8ctzEgKv6sPJ7RdPqxk=";
          allowedIPs = [ "10.100.0.5/32" ];
        }
      ];
    };
  };

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
