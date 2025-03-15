{ pkgs, ... }:
let
  jellyfin-ffmpeg-overlay = (
    final: prev: {
      jellyfin-ffmpeg = prev.jellyfin-ffmpeg.override {
        ffmpeg_7-full = prev.ffmpeg_7-full.override {
          withMfx = false;
          withVpl = true;
        };
      };
    }
  );
in
{
  nixpkgs.overlays = [
    jellyfin-ffmpeg-overlay
  ];
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];
  boot.kernelParams = [
    "i915.force_probe=46d1"
    "i915.enable_guc=2"
  ];
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
  # add jellyfin user to media group
  users.users.jellyfin.extraGroups = [ "media" ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    dataDir = "/lvmmedia/jellyfin";
    configDir = "/lvmmedia/jellyfin/config";
    # group="render";
    group = "media";
  };
  services.transmission = {
    enable = true;
    openFirewall = true;
    group = "media";
    settings = {
      download-dir = "/lvmmedia/transmission";
      incomplete-dir = "/lvmmedia/transmission/incomplete";
      rpc-bind-address = "0.0.0.0";
      rpc-enabled = true;
      rpc-whitelist-enabled = false;
      rpc-host-whitelist = "*";
    };
  };
  services.radarr = {
    enable = true;
    openFirewall = true;
    group = "media";
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
}
