{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.media;

  # https://wiki.nixos.org/w/index.php?title=Jellyfin&mobileaction=toggle_view_desktop#VAAPI_and_Intel_QSV_on_Arc_GPU
  # jellyfin-ffmpeg-overlay = (
  #   final: prev: {
  #     jellyfin-ffmpeg = prev.jellyfin-ffmpeg.override {
  #       ffmpeg_7-full = prev.ffmpeg_7-full.override {
  #         withMfx = false;
  #         withVpl = true;
  #       };
  #     };
  #   }
  # );
in
{
  options.local.media = {
    enable = mkEnableOption "media services (Jellyfin, Transmission, Radarr, Prowlarr)";

    dataPath = mkOption {
      type = types.str;
      default = "/var/lib/media";
      description = "Base path for media service data directories";
    };

    jellyfin = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Jellyfin media server";
      };

      dataDir = mkOption {
        type = types.str;
        default = "${cfg.dataPath}/jellyfin";
        description = "Jellyfin data directory";
      };

      configDir = mkOption {
        type = types.str;
        default = "${cfg.dataPath}/jellyfin/config";
        description = "Jellyfin configuration directory";
      };
    };

    transmission = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Transmission BitTorrent client";
      };

      downloadDir = mkOption {
        type = types.str;
        default = "${cfg.dataPath}/transmission";
        description = "Transmission download directory";
      };

      incompleteDir = mkOption {
        type = types.str;
        default = "${cfg.dataPath}/transmission/incomplete";
        description = "Transmission incomplete downloads directory";
      };

      rpcPort = mkOption {
        type = types.port;
        default = 9091;
        description = "Transmission RPC port";
      };
    };

    radarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Radarr movie management";
      };
    };

    prowlarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Prowlarr indexer management";
      };
    };

    hardwareAcceleration = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Intel hardware acceleration for media transcoding";
      };

      intelGpuTools = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Intel GPU tools";
      };
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open firewall ports for media services";
    };
  };

  config = mkIf cfg.enable {
    # Overlays for jellyfin-ffmpeg with hardware acceleration
    # nixpkgs.overlays = mkIf cfg.hardwareAcceleration.enable [
    #   jellyfin-ffmpeg-overlay
    # ];

    # Kernel modules and parameters for hardware acceleration
    boot = mkIf cfg.hardwareAcceleration.enable {
      initrd.availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];
      kernelParams = [
        "i915.force_probe=46d1"
        "i915.enable_guc=2"
      ];
    };

    # System packages
    environment.systemPackages =
      with pkgs;
      [
        vim
        wget
        git
        nano
        unzip
        get_iplayer
      ]
      ++ optionals cfg.jellyfin.enable [
        jellyfin
        jellyfin-web
        jellyfin-ffmpeg
      ];

    # Package overrides for hardware acceleration
    nixpkgs.config.packageOverrides = mkIf cfg.hardwareAcceleration.enable (pkgs: {
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
    });

    # Hardware acceleration
    hardware = mkIf cfg.hardwareAcceleration.enable {
      intel-gpu-tools.enable = cfg.hardwareAcceleration.intelGpuTools;
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          intel-vaapi-driver
          libva-vdpau-driver # error: 'vaapiVdpau' has been renamed to/replaced by 'libva-vdpau-driver'
          intel-compute-runtime
          vpl-gpu-rt
        ];
      };
    };

    # User groups
    users.groups.media = mkIf cfg.jellyfin.enable { };
    users.users.jellyfin = mkIf cfg.jellyfin.enable {
      extraGroups = [ "media" ];
    };

    # Services
    services = {
      jellyfin = mkIf cfg.jellyfin.enable {
        enable = true;
        # Don't open firewall here. Do it on the host
        # openFirewall = cfg.openFirewall;
        openFirewall = false;
        dataDir = cfg.jellyfin.dataDir;
        configDir = cfg.jellyfin.configDir;
        group = "media";
      };

      transmission = mkIf cfg.transmission.enable {
        enable = true;
        package = pkgs.transmission_4;
        # Don't open firewall here. Do it on the host
        # openFirewall = cfg.openFirewall;
        openFirewall = false;
        group = "media";
        settings = {
          download-dir = cfg.transmission.downloadDir;
          incomplete-dir = cfg.transmission.incompleteDir;
          rpc-bind-address = "0.0.0.0";
          rpc-enabled = true;
          rpc-whitelist-enabled = false;
          rpc-host-whitelist = "*";
          rpc-port = cfg.transmission.rpcPort;
        };
      };

      radarr = mkIf cfg.radarr.enable {
        enable = true;
        # Don't open firewall here. Do it on the host
        # openFirewall = cfg.openFirewall;
        openFirewall = false;
        group = "media";
      };

      prowlarr = mkIf cfg.prowlarr.enable {
        enable = true;
        # Don't open firewall here. Do it on the host
        # openFirewall = cfg.openFirewall;
        openFirewall = false;
      };
    };
    # Don't open firewall here. Do it on the host
    # # Firewall configuration
    # networking.firewall = mkIf cfg.openFirewall {
    #   enable = true;
    #   allowedTCPPorts = [ cfg.transmission.rpcPort ];
    # };
  };
}
