{
  pkgs,
  unstable,
  config,
  inputs,
  lib,
  ...
}:
let
  neolink = (pkgs.callPackage ../packages/neolink.nix { });

  # sddlite-mobilenet = (pkgs.callPackage ../packages/ssdlite_mobilenet_v2_coco.nix { });
  yolov7 = (pkgs.callPackage ../packages/yolov7.nix { });
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../modules/frigate.16.nix
  ];
  ####################################
  # System
  ####################################
  environment.defaultPackages = [
    pkgs.neofetch
    pkgs.htop
  ];
  environment.systemPackages = [
  ];

  ####################################
  # Secrets
  ####################################
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.generateKey = true;
  sops.secrets.headscale_alto = {
    sopsFile = "${inputs.secrets}/headscale/alto";
    format = "binary";
  };

  ####################################
  # Ports + Networking
  ####################################
  networking.hostName = "alto";
  networking.firewall = {
    allowedTCPPorts = [
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

  services.resolved = {
    enable = true;
    dnssec = "false";
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    authKeyFile = config.sops.secrets.headscale_alto.path;
    extraUpFlags = [
      "--advertise-exit-node"
      "--login-server=https://hs.pm4.uk"
    ];
    port = 49999;
    openFirewall = true;
  };

  networking.firewall.checkReversePath = "loose";

  sops.secrets.cloudflare_api_key = {
    sopsFile = "${inputs.secrets}/cloudflare_api/pm4.uk.enc";
    format = "binary";
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "alto_pm4_cert@pm4.uk";
    defaults.dnsResolver = "1.1.1.1";
    certs."wildcard.pm4.uk" = {
      credentialFiles."CF_DNS_API_TOKEN_FILE" = config.sops.secrets.cloudflare_api_key.path;
      dnsProvider = "cloudflare";
      domain = "*.pm4.uk";
    };
    certs."wildcard.coredev.pm4.uk" = {
      credentialFiles."CF_DNS_API_TOKEN_FILE" = config.sops.secrets.cloudflare_api_key.path;
      dnsProvider = "cloudflare";
      domain = "*.coredev.pm4.uk";
    };
  };
  users.groups.acme = {
    # This is for the nspawn container
    gid = 977;
  };
  services.caddy = {
    enable = true;
    extraConfig = ''
      (tailscale_auth) {
        forward_auth unix/${config.services.tailscaleAuth.socketPath} {
            uri /

            header_up Remote-Addr {http.request.remote.host}
            header_up Remote-Port {http.request.remote.port}
            header_up Expected-Tailnet ts.pm4.uk.

           	copy_headers {
            		Tailscale-User>X-Webauth-User
            		Tailscale-Name>X-Webauth-Name
            		Tailscale-Login>X-Webauth-Login
            		Tailscale-Tailnet>X-Webauth-Tailnet
            		Tailscale-Profile-Picture>X-Webauth-Profile-Picture
           	}
        }

        request_header X-Webauth-Email "{http.request.header.X-Webauth-User}@pm4.uk"
      }
    '';
    virtualHosts = {
      "frigate.pm4.uk" = {
        useACMEHost = "wildcard.pm4.uk";
        extraConfig = ''
          reverse_proxy localhost:8392
        '';
      };
      "home-assistant.pm4.uk" = {
        useACMEHost = "wildcard.pm4.uk";
        extraConfig = ''
          reverse_proxy localhost:8123
        '';
      };
    };
  };

  services.tailscaleAuth = {
    enable = true;
    user = "caddy";
    group = "caddy";
  };

  ####################################
  # Home Automation
  ####################################
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

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      serial.port = "/dev/serial/by-id/usb-Itead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_V2_b2c13e0a2789f0118a5609697aa08750-if00-port0";
      serial.adapter = "ember";
      mqtt.server = "mqtt://localhost:1883";
      frontend.enabled = true;
      frontend.port = 11883;
      homeassistant.enabled = true;
    };
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

  # Package overrides for hardware acceleration
  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
  };

  # Hardware acceleration
  hardware = {
    intel-gpu-tools.enable = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libva-vdpau-driver # error: 'vaapiVdpau' has been renamed to/replaced by 'libva-vdpau-driver'
        intel-compute-runtime
        vpl-gpu-rt
        libvdpau-va-gl
      ];
    };
  };

  services.nginx.virtualHosts."${config.local.services.frigate.hostname}" = {
    listen = [
      {
        addr = "0.0.0.0";
        port = 8392;
      }
    ];
  };
  local.services.frigate = {
    enable = true;
    package = pkgs.frigate;
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

        zones.frontgarden.coordinates = "0,0.655,0.113,0.635,0.672,0.685,0.682,0.087,0.999,0.078,1,1,0,1";
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
