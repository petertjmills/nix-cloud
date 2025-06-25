{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.seaweedfs-server;

  # Convert an attribute set to the config file format (key=value)
  configFile = pkgs.writeText "seaweedfs-server.conf" (
    concatStringsSep "\n" (mapAttrsToList (name: value: "${name}=${toString value}") cfg.settings)
  );

in
{
  options.local.seaweedfs-server = {
    enable = mkEnableOption "SeaweedFS server (master, volume, filer, etc. in one process)";

    package = mkOption {
      type = types.package;
      default = pkgs.seaweedfs;
      defaultText = literalExpression "pkgs.seaweedfs";
      description = "SeaweedFS package to use";
    };

    user = mkOption {
      type = types.str;
      default = "seaweedfs";
      description = "User account under which SeaweedFS server runs";
    };

    group = mkOption {
      type = types.str;
      default = "seaweedfs";
      description = "Group under which SeaweedFS server runs";
    };

    settings = mkOption {
      type = types.attrsOf (
        types.oneOf [
          types.str
          types.int
          types.bool
        ]
      );
      default = { };
      example = literalExpression ''
        {
          # Master settings
          master = true;
          "master.port" = 9333;
          "master.volumeSizeLimitMB" = 30000;
          "master.defaultReplication" = "001";

          # Volume settings
          volume = true;
          "volume.port" = 8080;
          "volume.max" = "8";
          dir = "/var/lib/seaweedfs/data";

          # Filer settings
          filer = true;
          "filer.port" = 8888;

          # S3 settings
          s3 = true;
          "s3.port" = 8333;

          # General settings
          ip = "10.0.0.5";
          "ip.bind" = "0.0.0.0";
        }
      '';
      description = ''
        SeaweedFS server configuration as an attribute set.
        See `weed help server` for available options.

        Options are specified as key-value pairs where the key is the
        command-line flag name (without leading dashes) and the value
        is the option value.
      '';
    };

    dataDirectories = mkOption {
      type = types.listOf types.str;
      default = [ "/var/lib/seaweedfs" ];
      description = "Directories to create for SeaweedFS data storage";
    };
  };

  config = mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      description = "SeaweedFS server user";
      home = "/var/lib/seaweedfs";
      createHome = true;
    };

    users.groups.${cfg.group} = { };

    # Create data directories
    systemd.tmpfiles.rules = map (
      dir: "d ${dir} 0750 ${cfg.user} ${cfg.group} - -"
    ) cfg.dataDirectories;

    # Install package
    environment.systemPackages = [ cfg.package ];

    # Create systemd service
    systemd.services.seaweedfs-server = {
      description = "SeaweedFS Unified Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/weed server -options=${configFile}";
        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = cfg.dataDirectories;

        # Resource limits
        LimitNOFILE = 65536;
      };
    };
  };
}
