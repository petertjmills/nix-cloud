{ modulesPath, config, lib, pkgs, ... }:
let
  jellyfin-ffmpeg-overlay = (final: prev: {
    jellyfin-ffmpeg = prev.jellyfin-ffmpeg.override {
      ffmpeg_7-full = prev.ffmpeg_7-full.override {
        withMfx = false;
        withVpl = true;
      };
    };
  });
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./disk-config.nix
      (modulesPath + "/profiles/qemu-guest.nix")
    ];

  nixpkgs.overlays = [
    jellyfin-ffmpeg-overlay
  ];
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.kernelParams = [ "i915.force_probe=46d1" "i915.enable_guc=2" ];
  boot.loader.grub.enable = true;
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "nimbus"; # Define your hostname.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  time.timeZone = "Europe/London";

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    nano
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    unzip
    get_iplayer
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.intel-gpu-tools.enable = true;
  hardware.opengl = {
    # hardware.opengl in 24.05
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver # previously vaapiIntel
      vaapiVdpau
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      # QSV on 11th gen or newer
      #intel-media-sdk # QSV up to 11th gen
      onevpl-intel-gpu
    ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    # group="render";
  };
  services.transmission = {
    enable = true;
    openFirewall = true;
    settings = {
      download-dir = "/data/transmission";
      incomplete-dir = "/data/transmission/incomplete";
      rpc-bind-address = "0.0.0.0";
      rpc-enabled = true;
      rpc-whitelist-enabled = false;
      rpc-host-whitelist = "*";
    };
  };
  services.radarr = {
    enable = true;
    openFirewall = true;
  };
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      9091
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
