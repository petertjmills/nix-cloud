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
  ####################################
  # System
  ####################################
  environment.defaultPackages = [
    pkgs.neofetch
    pkgs.htop
    inputs.escpos-server.packages.x86_64-linux.escpos-print
  ];
  environment.systemPackages = [
    pkgs.seaweedfs
  ];
  systemd.tmpfiles.rules = [
    "d '${config.services.radicale.settings.storage.filesystem_folder}' 0700 radicale radicale - -"
    "d '${config.services.transmission.settings.download-dir}' 0770 transmission media - -"
    "d '${config.services.transmission.settings.incomplete-dir}' 0770 transmission media - -"
  ];
  ####################################
  # Secrets
  ####################################
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.generateKey = true;
  sops.secrets.headscale_sky = {
    sopsFile = "${inputs.secrets}/headscale/sky";
    format = "binary";
  };

  ####################################
  # Backups
  ####################################

  services.restic.backups = {
    # "postgres" = { };
    # "jellyfin-settings" = { };
    # "media" = { };
    # "radicale" = { };
    # "frigate" = { };
    # "home-assistant" = { };
  };

  services.restic.server = {
    enable = true;
    appendOnly = true;
    dataDir = "/mnt/zfs/backups/restic";
    extraFlags = [
      # "--no-auth"
      "--proxy-auth-username=X-Webauth-User"
    ];
    listenAddress = "127.0.0.1:8480";
    privateRepos = true;
    prometheus = true;
  };

  services.usbmuxd.enable = true;

  ####################################
  # Ports + Networking
  ####################################
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

  services.resolved = {
    enable = true;
    dnssec = "false";
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

  sops.secrets.cloudflare_api_key = {
    sopsFile = "${inputs.secrets}/cloudflare_api/pm4.uk.enc";
    format = "binary";
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "sky_pm4_cert@pm4.uk";
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
      "radicale.pm4.uk" = {
        useACMEHost = "wildcard.pm4.uk";
        extraConfig = ''
          import tailscale_auth
          @get-root {
              method GET
              path /.web
          }

          redir @get-root /.web/
          reverse_proxy localhost:5232 {
              # replace "HOST" with configured hostname of URL (FQDN) in client
              header_up Host HOST
              # replace "PORT" with configured port of URL in client
              header_up X-Forwarded-Port PORT
              # Set http_x_remote_user to = X-Webauth-User
              header_up X-Remote-User "{http.request.header.X-Webauth-User}"
          }
        '';
      };
      "restic.pm4.uk" = {
        useACMEHost = "wildcard.pm4.uk";
        extraConfig = ''
          import tailscale_auth
          reverse_proxy localhost:8480
        '';
      };
      "openwebui.pm4.uk" = {
        useACMEHost = "wildcard.pm4.uk";
        extraConfig = ''
          import tailscale_auth
          reverse_proxy localhost:8358
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
  # Observability
  ####################################
  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "1m"; # "1m"
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

  ####################################
  # Storage
  ####################################
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

  fileSystems."/mnt/seaweed" = {
    device = "fuse";
    fsType = "fuse./run/current-system/sw/bin/weed";
    options = [
      "_netdev"
      "filer='0.0.0.0:8888'"
      "filer.path=/"
    ];
  };

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

  ####################################
  # Media
  ####################################
  local.media = {
    enable = true;
    dataPath = "/data/media"; # Custom base path

    jellyfin = { };

    transmission = {
      rpcPort = 9091;
    };

    hardwareAcceleration.enable = true;
  };

  ####################################
  # Organisation
  ####################################
  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "0.0.0.0:5232" ];
      # auth.type = "htpasswd";
      # auth.htpasswd_filename = "${inputs.secrets}/htpasswd";
      # auth.htpasswd_encryption = "bcrypt";
      auth.type = "http_x_remote_user";
      storage.filesystem_folder = "/data/radicale";
    };
  };

  ####################################
  # Dev
  ####################################

  containers."coredev" = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br0"; # Specify the bridge name
    # localAddress = "192.168.5.40/24";
    bindMounts = {
      ts-secret = {
        hostPath = config.sops.secrets.headscale_sky.path;
        isReadOnly = true;
        mountPoint = config.sops.secrets.headscale_sky.path;
      };
      wildcard-ts-pm4 = {
        hostPath = config.security.acme.certs."wildcard.coredev.pm4.uk".directory;
        mountPoint = "${config.security.acme.certs."wildcard.coredev.pm4.uk".directory}:";
        isReadOnly = true;
      };
      # cf-secret = {
      #   hostPath = config.sops.secrets.cloudflare_api_key.path;
      #   isReadOnly = true;
      #   mountPoint = config.sops.secrets.cloudflare_api_key.path;
      # };
    };
    config =
      let
        sslCertDir = config.security.acme.certs."wildcard.coredev.pm4.uk".directory;
      in
      {
        # coredev #####################################################################
        imports = [
          inputs.ory-nix-auth.nixosModules."x86_64-linux".default
        ];
        networking.useHostResolvConf = lib.mkForce false;
        services.resolved.enable = true;
        services.resolved.fallbackDns = [
          "1.1.1.1"
          "1.0.0.1"
        ];

        networking.hosts = {
          "127.0.0.1" = [ "coredev.ts.pm4.uk" ];
        };
        networking.useDHCP = lib.mkForce true;

        environment.defaultPackages = [
          pkgs.tailscale
        ];

        services.tailscale = {
          enable = true;
          useRoutingFeatures = "both";
          authKeyFile = config.sops.secrets.headscale_sky.path;
          interfaceName = "userspace-networking";
          extraUpFlags = [
            "--login-server=https://hs.pm4.uk"
          ];
          port = 49999;
          openFirewall = true;
        };

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
            {
              name = "kratos-main";
              ensureDBOwnership = true;
              ensureClauses.createdb = true;
              ensureClauses.createrole = true;
            }
          ];
          ensureDatabases = [
            "metachroma_dev"
            "metachroma_test"
            "kratos-main"
          ];
        };

        # Mirror the pinned GID inside the container
        users.groups.acme = {
          gid = 977;
        };

        # Add caddy to the acme group
        users.users.caddy.extraGroups = [ "acme" ];

        # Caddy reverse proxy configuration
        services.caddy = {
          enable = true;

          virtualHosts."auth.coredev.pm4.uk" = {
            extraConfig = ''
              tls ${sslCertDir}/cert.pem ${sslCertDir}/key.pem
              reverse_proxy * localhost:4433
            '';
          };
        };

        services.kratos.core = {
          enable = true;
          # package = unstable.kratos;

          # Bootstrap identities (for development/testing)
          ensureIdentitiesFile = ../config/coredev/users.json;

          settings = {
            dsn = "postgres://kratos-main:secret@localhost:5432/kratos-main?host=/var/run/postgresql&sslmode=disable&max_conns=20&max_idle_conns=4";
            serve = {
              public = {
                base_url = "https://auth.coredev.pm4.uk";
                port = 4433;
                cors.enabled = true;
              };
              admin = {
                base_url = "http://localhost:4434";
              };
            };

            identity = {
              default_schema_id = "default";
              schemas = [
                {
                  id = "default";
                  url = "file://${../config/coredev/user-schema.json}";
                }
              ];
            };

            selfservice.methods = {
              password.enabled = true;
              code.enabled = true;
            };

            selfservice.flows.registration.enabled = false;

            selfservice.default_browser_return_url = "https://auth.coredev.pm4.uk";
          };
        };

        systemd.services.kratos-core.wantedBy = lib.mkForce [ ];

        # /coredev #####################################################################
      };
  };

  ####################################
  # AI
  ####################################
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "open-webui"
    ];
  services.open-webui = {
    enable = true;
    host = "127.0.0.1";
    port = 8358;
    environment = {
      WEBUI_URL = "https://openwebui.pm4.uk";
      # ENABLE_SIGNUP = "false";
      WEBUI_ADMIN_EMAIL = "admin@example.com";
      WEBUI_ADMIN_PASSWORD = "adminpassword";
      WEBUI_AUTH_TRUSTED_EMAIL_HEADER = "X-Webauth-Email";
      WEBUI_AUTH_TRUSTED_NAME_HEADER = "X-Webauth-Name";
      CHAT_STREAM_RESPONSE_CHUNK_MAX_BUFFER_SIZE = "34359738368";
      ENABLE_CHAT_RESPONSE_BASE64_IMAGE_URL_CONVERSION = "True";
    };
  };
}
