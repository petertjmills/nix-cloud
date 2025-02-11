{ modulesPath, config, lib, pkgs, ... }:
let
  jack_delay = pkgs.stdenv.mkDerivation {
    name = "jack_delay";
    src = pkgs.fetchFromGitHub {
      owner = "ericfont";
      repo = "jack_delay";
      rev = "master";
      sha256 = "sha256-7U+co0hAV0YuKY0HOgi1iifa8XCnHsvVwlTtW2EsIEc=";
    };

    buildInputs = [ pkgs.jack2 ];

    buildPhase = ''
      cd source
      make
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp jack_delay $out/bin
    '';
  };
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

  networking.hostName = "nixmusic"; # Define your hostname.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  time.timeZone = "Europe/London";

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    neofetch

    jack_delay
    jack-example-tools
  ];
  services.openssh.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [

    ];
  };

  musnix.enable = true;
  musnix.kernel.realtime = true;
  services.jack = {
    jackd.enable = true;
    jackd.extraOptions = [ "-R" "-d" "alsa" "-d" "hw:USB"];
    # support ALSA only programs via ALSA JACK PCM plugin
    alsa.enable = false;
    # support ALSA only programs via loopback device (supports programs like Steam)

    loopback = {
      enable = true;
      # buffering parameters for dmix device to work with ALSA only semi-professional sound programs
      #dmixConfig = ''
      #  period_size 2048
      #'';
    };
  };


  users.users.root.extraGroups = [ "audio" "jackaudio" ];

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
