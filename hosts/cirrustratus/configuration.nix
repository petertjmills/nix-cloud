{ modulesPath
, config
, lib
, pkgs
, ...
}:
let
  backupPath = "/data/borgbackup";
in
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

  networking.hostName = "cirrustratus"; # Define your hostname.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  time.timeZone = "Europe/London";

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    neofetch
    rclone
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.borgbackup.repos = {
    silversurfer_backups = {
      # silversurfer
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8tQOhDkrQO4q3W7JdernvtL1v+aiNsjozN41qrfs2n Silversurfer"
      ];
      path = "${backupPath}/silversurfer_backups";
      user = "silversurfer_backups";
    };
    macbookpro_2015 = {
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQ6Qz5vAJG38dmP1C9nYETNzUrlRo5LCkeSM2LMTKVi Peter@Peters-MacBook-Pro-3.local"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUkQkIBpVCIFpJtLgjmCnm//lqMS1vNYOmXO4Ff1fqf sophie@Peters-MacBook-Pro-3.local"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAo6iE0CBeo9SQlK8UuXGzl/gMHlEJgQ1o+6vqiJN9mE katrinamills@Peters-MBP-3.lan"
      ];
      path = "${backupPath}/macbookpro_2015";
      user = "macbookpro_2015";
    };
  };

  age.secrets.b2_backup.file = ../../secrets/b2_backup.age;

  systemd.services.rclone-backup = {
    wantedBy = [ "multi-user.target" ];
    description = "Rclone service";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.rclone}/bin/rclone sync ${backupPath} remote:petermills-backups --config ${config.age.secrets.b2_backup.path}'";
      # Log when completed
      ExecStartPost = "${pkgs.systemd}/bin/systemd-cat echo 'Rclone backup completed'";
    };
  };

  systemd.timers.rclone-backup = {
    description = "Rclone Backup Timer";
    timerConfig = {
      OnCalendar = "Mon *-*-* 00:00:00"; # Run every Monday at midnight
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      9090
      3000
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
