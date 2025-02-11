{ 
  modulesPath, 
  config, 
  lib, 
  pkgs,
  ... 
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./disk-config.nix
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../services/test.nix
  ];

  nixpkgs.overlays = [
    ( import ../../packages )
  ];

  boot.loader.grub.enable = true;
  
  nix.settings.experimental-features = ["nix-command" "flakes"];

  networking.hostName = "altostratus"; # Define your hostname.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  time.timeZone = "Europe/London";

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    neofetch
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    settings.port = 5432;
    authentication = pkgs.lib.mkOverride 10 ''
      #...
      #type database DBuser origin-address auth-method
      # ipv4
      local all all              trust
      host  all      all     127.0.0.1/32   trust
      host all       all     ::1/128        trust
      host  all      all     192.168.86.210/32   trust
      # ipv6
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE finance WITH LOGIN PASSWORD 'finance' CREATEDB;
      CREATE DATABASE finance;
      GRANT ALL PRIVILEGES ON DATABASE finance TO finance;
      ALTER SCHEMA public OWNER TO finance;
    '';
  };

  # age.secrets.finance_tracker_env.file = ../../secrets/finance_tracker_env.age;
  services.financeTracker = {
    enable = true;
    # env_file = ../../services/finance-tracker.env;
    # postgresServiceName = "postgresql.service";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 3000 5432 ];
  };

  users.users.root.openssh.authorizedKeys.keys=[
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
