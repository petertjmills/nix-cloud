{
  description = "My nix cloud";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    terranix.url = "github:terranix/terranix";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:petertjmills/nixvim";
  };

  outputs =
    {
      self,
      nixpkgs,
      terranix,
      disko,
      ...
    }@inputs:
    let
      hosts = {
        sky =
          let
            system = "x86_64-linux";
          in
          {
            inherit system;
            disko = import ./disko/nvme_uefi.nix;

            modules = [
              (
                { pkgs, ... }:
                {
                  boot.loader.grub.enable = true;
                  boot.loader.grub.efiSupport = true;
                  boot.loader.grub.efiInstallAsRemovable = true;
                  boot.supportedFilesystems = [ "zfs" ];
                  boot.zfs.extraPools = [ "tank" ];
                  nix.settings.experimental-features = [
                    "nix-command"
                    "flakes"
                  ];
                  networking.hostId = "d0a95792";
                  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

                  environment.systemPackages = [
                    inputs.nixvim.packages.${system}.default
                    pkgs.zfs
                    pkgs.neofetch
                    pkgs.git
                    pkgs.just
                  ];
                  services.openssh.enable = true;
                  programs.zsh = {
                    enable = true;
                    enableCompletion = true;
                    syntaxHighlighting.enable = true;

                    shellAliases = {
                      ll = "ls -lah";
                    };

                    ohMyZsh = {
                      enable = true;
                      plugins = [ "git" ];
                      theme = "dieter";
                    };
                  };
                  users.defaultUserShell = pkgs.zsh;
                  users.users.root.openssh.authorizedKeys.keys = [
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8tQOhDkrQO4q3W7JdernvtL1v+aiNsjozN41qrfs2n Silversurfer"
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyxwQIShLIk/qHVnEkRWC+7/V82brDH3s0tBwpnttVi macmini"
                  ];
                  networking.nftables.enable = true;
                  # networking.firewall.trustedInterfaces = [ "incusbr0" ];
                  networking.bridges = {
                    "br0" = {
                      interfaces = [ "enp1s0" ];
                    };
                  };
                  networking.interfaces.br0.ipv4.addresses = [
                    {
                      address = "192.168.86.60";
                      prefixLength = 24;
                    }
                  ];
                  networking.useDHCP = false;
                  networking.defaultGateway = "192.168.86.1";
                  networking.nameservers = [ "8.8.8.8" ];
                  virtualisation.incus = {
                    enable = true;
                    ui.enable = true;
                    preseed = {
                      config."core.https_address" = "[::]:8443";
                      config."images.auto_update_interval" = "0";
                      networks = [ ];
                      storage_pools = [
                        # Only run this once. if it fails use incus storage
                        # {
                        #   config.source = "tank";
                        #   name = "incus_zfs_pool";
                        #   driver = "zfs";
                        # }
                      ];
                      profiles = [
                        {
                          devices.eth0 = {
                            name = "eth0";
                            nictype = "bridged";
                            parent = "br0";
                            type = "nic";
                          };
                          devices.root = {
                            path = "/";
                            pool = "incus_zfs";
                            type = "disk";
                          };
                          name = "default";
                        }
                      ];
                      projects = [ ];
                      cluster = null;
                    };
                  };

                  system.stateVersion = "24.05";
                }
              )
            ];
          };
        test =
          let
            system = "x86_64-linux";
          in
          {
            disko = { };
            inherit system;

            modules = [
              "${inputs.nixpkgs}/nixos/modules/virtualisation/lxd-virtual-machine.nix"
              (
                { pkgs, ... }:
                {
                  environment.systemPackages = [ pkgs.neofetch ];
                  users.users.root.openssh.authorizedKeys.keys = [
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8tQOhDkrQO4q3W7JdernvtL1v+aiNsjozN41qrfs2n Silversurfer"
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyxwQIShLIk/qHVnEkRWC+7/V82brDH3s0tBwpnttVi macmini"
                  ];
                }
              )

            ];

          };

      };

    in
    {
      nixosConfigurations = builtins.mapAttrs (
        name: value:
        nixpkgs.lib.nixosSystem {
          system = value.system;
          modules = [
            disko.nixosModules.disko
            {
              disko = value.disko;
              networking.hostName = name;
            }
          ] ++ value.modules;
        }
      ) hosts;

    };
}
