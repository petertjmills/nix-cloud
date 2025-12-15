{
  pkgs,
  unstable,
  config,
  inputs,
  lib,
  ...
}:
let
  weedFuseWrapper = pkgs.writeScriptBin "weed-fuse-debug" ''
    echo "[ ] ARGS: $@" >> /var/log/weed-fuse-debug.log
    exec ${pkgs.seaweedfs}/bin/weed "$@"
  '';

  neolink = (pkgs.callPackage ../packages/neolink.nix { });

  # sddlite-mobilenet = (pkgs.callPackage ../packages/ssdlite_mobilenet_v2_coco.nix { });
  yolov7 = (pkgs.callPackage ../packages/yolov7.nix { });
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../modules/seaweedfs-server.nix
    ../modules/media.nix
    ../modules/frigate.16.nix
  ];

  networking.hostName = "sky";
  networking.firewall = {
    allowedTCPPorts = [
      # config.services.prometheus.port
      # config.services.loki.configuration.server.http_listen_port
      # config.services.grafana.settings.server.http_port

      # unbound
      53
      5432

      #Jellyfin
      8096

      # HA
      8123
      1400 # Sonos

      # Music Assistant
      8095
      8097
    ];
    allowedUDPPorts = [
      53
      1400
    ];
  };

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.generateKey = true;
  sops.secrets.headscale_sky = {
    sopsFile = "${inputs.secrets}/headscale/sky";
    format = "binary";
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    authKeyFile = config.sops.secrets.headscale_sky.path;
    extraUpFlags = [
      "--advertise-exit-node"
      "--login-server=https://hs.pm4.uk"
    ];
    port = 49999;
    openFirewall = true;
  };

  networking.firewall.checkReversePath = "loose";

  environment.defaultPackages = [
    pkgs.neofetch
    pkgs.htop

    # neolink
  ];

  # services.traefik = {
  #   enable = true;
  #   staticConfigOptions = {
  #     entryPoints.web = {
  #       address = ":80";
  #       http.redirections.entryPoint.to = "websecure";
  #       http.redirections.entryPoint.scheme = "https";
  #     };
  #     entryPoints.websecure = {
  #       address = ":443";
  #     };
  #     # Replace this with cert from security.acme (to centralise)
  #     # certificateResolvers.main.acme = {
  #     #   email = "";
  #     #   storage = "";
  #     #   dnsChallenge.provider = "cloudflare";
  #     #   dnsChallenge.delayBeforeCheck = 30;
  #     # };

  #   };
  #   dynamicConfigOptions = {
  #     # http.routers.
  #   };
  # };
  # sops.secrets.cloudflare_api_key = {
  #   sopsFile = "${inputs.secrets}/cloudflare_api/pm4.uk.enc";
  #   format = "binary";
  # };
  # security.acme = {
  #   acceptTerms = true;
  #   defaults.email = "cirrus_pm4_cert@pm4.uk";
  #   defaults.dnsResolver = "1.1.1.1";
  #   certs."wildcard.pm4.uk" = {
  #     credentialFiles."CF_DNS_API_TOKEN_FILE" = config.sops.secrets.cloudflare_api_key.path;
  #     dnsProvider = "cloudflare";
  #     domain = "*.pm4.uk";
  #   };
  # };
  # services.caddy = {
  #   enable = true;
  #   virtualHosts."frigate.pm4.uk".extraConfig = ''
  #     reverse_proxy http://localhost:8971
  #     tls ${config.security.acme.certs."wildcard.pm4.uk".directory}/cert.pem ${
  #       config.security.acme.certs."wildcard.pm4.uk".directory
  #     }/key.pem {
  #       protocols tls1.3
  #     }
  #     import logging frigate.pm4.uk
  #   '';
  # };

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s"; # "1m"
    # scrapeConfigs = scrapeConfigs;
  };

  # environment.etc."grafana/dashboards/incus-dashboard.json".source =
  #   ../configs/grafana/incus-dashboard.json;
  # environment.etc."grafana/dashboards/seaweedfs-dashboard.json".source =
  #   ../configs/grafana/seaweedfs-dashboard.json;
  # environment.etc."grafana/dashboards/loki-dashboard.json".source =
  #   ../configs/grafana/loki-dashboard.json;

  # services.grafana = {
  #   enable = true;
  #   settings = {
  #     server = {
  #       http_port = 3000;
  #       http_addr = "0.0.0.0";
  #     };
  #
  # };
  #   provision = {
  #     enable = true;

  #     dashboards.settings = {
  #       apiVersion = 1;

  #       providers = [
  #         {
  #           name = "default";
  #           options.path = "/etc/grafana/dashboards";
  #         }
  #       ];
  #     };
  #   };
  # };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_address = "0.0.0.0";
        http_listen_port = 3100;
      };

      common = {
        ring.instance_addr = "127.0.0.1";
        ring.kvstore.store = "inmemory";
        replication_factor = 1;
        path_prefix = "/tmp/loki";
      };

      schema_config.configs = [
        {
          from = "2020-05-15";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      storage_config.filesystem.directory = "/tmp/loki/chunks";

    };
  };

  local.seaweedfs-server = {
    enable = true;
    # package = pkgs.callPackage ../packages/seaweedfs.nix { };
    package = unstable.seaweedfs;
    settings = {
      # General settings
      ip = "sky";
      "ip.bind" = "0.0.0.0";
      dir = "/mnt/zfs/seaweedfs";

      # Enable and configure components
      master = true;
      "master.port" = 9333;
      "master.port.grpc" = 19333;
      "master.volumeSizeLimitMB" = 1024;

      volume = true;
      "volume.port" = 8080;
      "volume.max" = "0"; # free space/volumeSizeLimit

      filer = true;
      "filer.port" = 8888;

      s3 = true;
      "s3.port" = 8333;

      webdav = true;
      "webdav.port" = 8443;
      "webdav.filer.path" = "/";
    };

    dataDirectories = [
      "/data/seaweedfs"
      "/mnt/zfs/seaweedfs"
    ];
  };
  environment.systemPackages = [
    pkgs.seaweedfs
  ];
  fileSystems."/mnt/seaweed" = {
    device = "fuse";
    fsType = "fuse./run/current-system/sw/bin/weed";
    options = [
      "_netdev"
      "filer='0.0.0.0:8888'"
      "filer.path=/"
    ];
  };

  local.media = {
    enable = true;
    dataPath = "/data/media"; # Custom base path

    jellyfin = { };

    transmission = {
      rpcPort = 9091;
    };

    hardwareAcceleration.enable = true;
  };

  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "0.0.0.0:5232" ];
      auth.type = "htpasswd";
      auth.htpasswd_filename = "${inputs.secrets}/htpasswd";
      auth.htpasswd_encryption = "bcrypt";
      storage.filesystem_folder = "/data/radicale";
    };
  };

  systemd.tmpfiles.rules = [
    "d '${config.services.radicale.settings.storage.filesystem_folder}' 0700 radicale radicale - -"
    "d '${config.services.transmission.settings.download-dir}' 0770 transmission media - -"
    "d '${config.services.transmission.settings.incomplete-dir}' 0770 transmission media - -"
  ];

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
      host  all      all     100.64.0.5/32   trust
      host all all 100.64.0.10/32 trust
      # ipv6
    '';
    ensureUsers = [
      {
        name = "metachroma_dev";
        ensureDBOwnership = true;
      }
      {
        name = "metachroma_test";
        ensureDBOwnership = true;
        ensureClauses.createdb = true;
      }
    ];
    ensureDatabases = [
      "metachroma_dev"
      "metachroma_test"
    ];
  };

  # neolink

  sops.secrets.neolink = {
    sopsFile = "${inputs.secrets}/neolink/config.toml";
    format = "binary";
    path = "/etc/neolink/config.toml";
    restartUnits = [ "neolink.service" ];
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        acl = [ "pattern readwrite #" ];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  sops.secrets.frigate-env = {
    sopsFile = "${inputs.secrets}/neolink/frigate.env";
    restartUnits = [
      "frigate.service"
      "go2rtc.service"
    ];
    format = "dotenv";
  };
  services.go2rtc = {
    enable = true;
    # package = pkgs.callPackage ../packages/go2rtc.nix { };
    settings = {
      streams.frontdoor = [
        "$\{FRIGATE_FRONT_DOOR_FLV_MAIN}"
        "$\{FRIGATE_FRONT_DOOR_RTSP_MAIN}"
      ];
      streams.frontdoorsub = [
        "$\{FRIGATE_FRONT_DOOR_FLV_SUB}"
        "$\{FRIGATE_FRONT_DOOR_RTSP_SUB}"
      ];

      rtsp.listen = ":8556";
      ffmpeg.bin = lib.getExe pkgs.ffmpeg-full;
    };
  };
  systemd.services.go2rtc.serviceConfig.EnvironmentFile = "${config.sops.secrets.frigate-env.path}";
  hardware.opengl.extraPackages = with pkgs; [
    vaapiIntel
    libvdpau-va-gl
    intel-media-driver
  ];
  local.services.frigate = {
    enable = true;
    package = unstable.frigate;
    hostname = "frigate.pm4.uk";
    vaapiDriver = "iHD";
    settings = {
      mqtt = {
        enabled = true;
        host = "127.0.0.1";
        port = 1883;
      };
      detectors.ov.type = "openvino";
      detectors.ov.device = "GPU";

      model = {
        model_type = "yolo-generic";
        width = 320;
        height = 320;
        input_tensor = "nchw";
        input_dtype = "float";
        path = "${yolov7}/yolov7-320.onnx";
        labelmap_path = "${yolov7}/coco-80.txt";
      };

      ffmpeg.path = pkgs.jellyfin-ffmpeg;
      ffmpeg.hwaccel_args = "preset-vaapi";

      record = {
        enabled = true;
        retain.days = 7;
        retain.mode = "motion";
        alerts.retain.days = 30;
        detections.retain.days = 30;
      };

      snapshots = {
        enabled = true;
        retain.default = 30;
      };

      cameras.livingroom = {
        enabled = true;
        motion.mask = "0.336,0.007,0.333,0.096,0.658,0.08,0.661,0.001";
        motion.threshold = 30;
        motion.contour_area = 10;
        motion.improve_contrast = true;
        detect.fps = 5;
        ffmpeg.output_args.record = "preset-record-generic-audio-copy";
        ffmpeg.inputs = [
          {
            path = "rtsp://127.0.0.1:8554/LivingRoom";
            input_args = "preset-rtsp-restream";
            roles = [ "record" ];
          }
          {
            path = "rtsp://127.0.0.1:8554/LivingRoom/Sub";
            input_args = "preset-rtsp-restream";
            roles = [
              "detect"
            ];
          }
        ];
      };
      cameras.frontdoor = {
        enabled = true;
        motion.mask = "0.271,0.012,0.271,0.061,0.709,0.062,0.708,0.008";
        motion.threshold = 30;
        motion.contour_area = 10;
        motion.improve_contrast = true;

        zones.frontgarden.coordinates = "0.001,0.561,0.063,0.57,0.663,0.669,0.682,0.087,0.999,0.078,1,1,0,1";
        review.alerts.required_zones = [ "frontgarden" ];

        detect.fps = 5;
        ffmpeg.output_args.record = "preset-record-generic-audio-copy";
        ffmpeg.inputs = [
          {
            path = "rtsp://127.0.0.1:8556/frontdoor?mp4";
            input_args = "preset-rtsp-restream";
            roles = [ "record" ];
          }
          {
            path = "rtsp://127.0.0.1:8556/frontdoorsub?mp4";
            input_args = "preset-rtsp-restream";
            roles = [
              "detect"
            ];
          }
        ];
      };
    };
  };
  systemd.services.frigate.serviceConfig.EnvironmentFile = "${config.sops.secrets.frigate-env.path}";

  # Home Assistant
  virtualisation.podman = {
    enable = true;
  };
  environment.etc."home-assistant/config/hello.txt".source = pkgs.writeText "hello.txt" ''
    hello
  '';
  environment.etc."music-assistant/config/hello.txt".source = pkgs.writeText "hello.txt" ''
    hlelo
  '';
  virtualisation.oci-containers = {
    backend = "podman";
    containers.neolink = {
      image = "quantumentangledandy/neolink:v0.6.2";
      ports = [ "127.0.0.1:8554:8554" ];
      volumes = [
        "${config.sops.secrets.neolink.path}:/etc/neolink/config.toml"
      ];
      cmd = [
        "neolink"
        "mqtt-rtsp"
        "--config"
        "/etc/neolink/config.toml"
      ];
      extraOptions = [ "--network=host" ];
    };
    containers.homeassistant = {
      volumes = [ "/etc/home-assistant/config:/config" ];
      environment.TZ = "Europe/London";
      # Note: The image will not be updated on rebuilds, unless the version label changes
      image = "ghcr.io/home-assistant/home-assistant:stable";
      extraOptions = [
        # Use the host network namespace for all sockets
        "--network=host"
        # Pass devices into the container, so Home Assistant can discover and make use of them
        # "--device=/dev/ttyACM0:/dev/ttyACM0"
      ];
    };

    containers.musicassistant = {
      volumes = [ "/etc/music-assistant:/data" ];
      image = "ghcr.io/music-assistant/server:latest";
      extraOptions = [ "--network=host" ];
    };
  };

}
