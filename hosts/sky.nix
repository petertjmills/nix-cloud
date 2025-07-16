{
  pkgs,
  config,
  inputs,
  ...
}:
let
  weedFuseWrapper = pkgs.writeScriptBin "weed-fuse-debug" ''
    echo "[ ] ARGS: $@" >> /var/log/weed-fuse-debug.log
    exec ${pkgs.seaweedfs}/bin/weed "$@"
  '';
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../modules/seaweedfs-server.nix
    ../modules/media.nix
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
    ];
    allowedUDPPorts = [ 53 ];
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
  ];

  services.traefik = {
    enable = true;
    staticConfigOptions = {
      entryPoints.web = {
        address = ":80";
        http.redirections.entryPoint.to = "websecure";
        http.redirections.entryPoint.scheme = "https";
      };
      entryPoints.websecure = {
        address = ":443";
      };
      # Replace this with cert from security.acme (to centralise)
      # certificateResolvers.main.acme = {
      #   email = "";
      #   storage = "";
      #   dnsChallenge.provider = "cloudflare";
      #   dnsChallenge.delayBeforeCheck = 30;
      # };

    };
    dynamicConfigOptions = {
      # http.routers.
    };
  };

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

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        http_addr = "0.0.0.0";
      };
    };
    provision = {
      enable = true;

      dashboards.settings = {
        apiVersion = 1;

        providers = [
          {
            name = "default";
            options.path = "/etc/grafana/dashboards";
          }
        ];
      };
    };
  };

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
    package = pkgs.callPackage ../packages/seaweedfs.nix { };
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
      # ipv6
    '';
    ensureUsers = [
      {
        name = "metachroma_dev";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [
      "metachroma_dev"
    ];
  };

}
