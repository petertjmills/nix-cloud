{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.seaweedfs;

  # Helper function to create port options
  mkPortOption =
    default: description:
    mkOption {
      type = types.port;
      default = default;
      description = description;
    };

  # Helper function to create boolean options
  mkEnableOption' =
    name: default: description:
    mkEnableOption (description) // { default = default; };
in
{
  options.services.seaweedfs = {
    enable = mkEnableOption "SeaweedFS distributed file system";
    enableServer = mkEnableOption "Enable SeaweedFS server components";

    package = mkOption {
      type = types.package;
      default = pkgs.seaweedfs;
      description = "Package to install SeaweedFS from";
    };

    user = mkOption {
      type = types.str;
      default = "seaweedfs";
      description = "User account under which SeaweedFS runs.";
    };

    group = mkOption {
      type = types.str;
      default = "seaweedfs";
      description = "Group account under which SeaweedFS runs.";
    };

    master = {
      enable = mkEnableOption' "master" true "Enable SeaweedFS master server";
      port = mkPortOption 9333 "Port for master server";
      grpcPort = mkPortOption 19333 "Port for master server gRPC";
      metricsPort = mkPortOption 29333 "Port for master server metrics";
      volumeSizeLimitMB = mkOption {
        type = types.int;
        default = 1000;
        description = "Maximum size limit for volumes in MB";
      };
      dirPath = mkOption {
        type = types.path;
        default = "/lvm_data/seaweedfs/master";
        description = "Directory path for master metadata";
      };
      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra arguments for master server";
      };
    };

    volume = {
      enable = mkEnableOption' "volume" true "Enable SeaweedFS volume server";
      instances = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Unique identifier for this volume instance";
              };
              port = mkOption {
                type = types.port;
                description = "Port for this volume server instance";
              };
              grpcPort = mkOption {
                type = types.port;
                description = "Port for this volume server gRPC";
              };
              metricsPort = mkOption {
                type = types.port;
                description = "Port for this volume server metrics";
              };
              dirPath = mkOption {
                type = types.str;
                description = "Directory path for volume storage";
              };
              diskType = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Optional disk type (e.g., 'zfs', 'lvm')";
              };
              max = mkOption {
                type = types.int;
                default = 0;
                description = "Max number of volumes, 0 for unlimited";
              };
              extraArgs = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Extra arguments for this volume server";
              };
            };
          }
        );
        default = [
          {
            name = "zfs-lvm";
            port = 8080;
            grpcPort = 18080;
            metricsPort = 28080;
            dirPath = "/zfs_data/seaweedfs/volumes,/lvm_data/seaweedfs/volumes";
            diskType = "zfs,lvm";
            max = 0;
          }
          {
            name = "root";
            port = 8081;
            grpcPort = 18081;
            metricsPort = 28081;
            dirPath = "/data";
            max = 0;
          }
        ];
        description = "Volume server instances configuration";
      };
    };

    filer = {
      enable = mkEnableOption' "filer" true "Enable SeaweedFS filer server";
      port = mkPortOption 8888 "Port for filer server";
      grpcPort = mkPortOption 18888 "Port for filer server gRPC";
      metricsPort = mkPortOption 28888 "Port for master server metrics";
      configPath = mkOption {
        type = types.path;
        default = "/etc/seaweedfs/filer.toml";
        description = "Path to filer configuration file";
      };
      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra arguments for filer server";
      };
    };

    s3 = {
      enable = mkEnableOption' "s3" true "Enable SeaweedFS S3 gateway";
      port = mkPortOption 8333 "Port for S3 gateway";
      metricsPort = mkPortOption 28333 "Port for master server metrics";
      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra arguments for S3 gateway";
      };
    };

    mount = {
      enable = mkEnableOption "SeaweedFS FUSE mount";
      instances = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Unique identifier for this mount point";
              };
              mountPoint = mkOption {
                type = types.path;
                description = "Path where the filesystem will be mounted";
              };
              filerAddress = mkOption {
                type = types.str;
                default = "localhost:8888";
                description = "Address of the filer server (host:port)";
              };
              collection = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Optional collection name";
              };
              path = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Optional path prefix in the filer";
              };
              extraArgs = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Extra arguments for this mount";
              };
            };
          }
        );
        default = [ ];
        description = "FUSE mount configurations";
      };
    };

    dataDirectories = mkOption {
      type = types.listOf types.str;
      default = [
        "/lvm_data/seaweedfs/master"
        "/zfs_data/seaweedfs/volumes"
        "/lvm_data/seaweedfs/volumes"
        "/lvm_data/seaweedfs/filerldb2"
        "/data"
        "/etc/seaweedfs"
      ];
      description = "Directories to create for SeaweedFS data storage";
    };

    filerConfig = mkOption {
      type = types.lines;
      default = ''
        [filer.options]
          recursive_delete = false

        [leveldb2]
          enabled = true
          dir = "/lvm_data/seaweedfs/filerldb2"
      '';
      description = "Configuration for the filer.toml file";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open firewall ports for SeaweedFS services";
    };
  };

  config = mkMerge [
    (mkIf cfg.enableServer ({

      environment.systemPackages = [ cfg.package ];

      networking.firewall = mkIf cfg.openFirewall {
        allowedTCPPorts =
          (lib.optional cfg.master.enable cfg.master.port)
          ++ (lib.optional cfg.master.enable cfg.master.metricsPort)
          ++ (lib.optional cfg.master.enable cfg.master.grpcPort)
          ++ (lib.concatMap (vol: [
            vol.port
            vol.metricsPort
            vol.grpcPort
          ]) cfg.volume.instances)
          ++ (lib.optional cfg.filer.enable cfg.filer.port)
          ++ (lib.optional cfg.filer.enable cfg.filer.grpcPort)
          ++ (lib.optional cfg.filer.enable cfg.filer.metricsPort)
          ++ (lib.optional cfg.s3.enable cfg.s3.port)
          ++ (lib.optional cfg.s3.enable cfg.s3.metricsPort);
        allowedUDPPorts =
          (lib.optional cfg.master.enable cfg.master.port)
          ++ (lib.optional cfg.master.enable cfg.master.metricsPort)
          ++ (lib.optional cfg.master.enable cfg.master.grpcPort)
          ++ (lib.concatMap (vol: [
            vol.port
            vol.metricsPort
            vol.grpcPort
          ]) cfg.volume.instances)
          ++ (lib.optional cfg.filer.enable cfg.filer.port)
          ++ (lib.optional cfg.filer.enable cfg.filer.grpcPort)
          ++ (lib.optional cfg.filer.enable cfg.filer.metricsPort)
          ++ (lib.optional cfg.s3.enable cfg.s3.port)
          ++ (lib.optional cfg.s3.enable cfg.s3.metricsPort);
      };

      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        description = "SeaweedFS User";
        createHome = true;
        home = "/var/lib/seaweedfs";
      };

      users.groups.${cfg.group} = {
        name = cfg.group;
      };

      systemd.tmpfiles.rules = (
        map (dir: "d ${dir} 0770 ${cfg.user} ${cfg.group} - -") cfg.dataDirectories
      );

      environment.etc."seaweedfs/filer.toml".text = cfg.filerConfig;

      systemd.services = mkMerge [
        # Master service
        (mkIf cfg.master.enable {
          "seaweedfs-master" = {
            description = "SeaweedFS Master Server";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "simple";
              User = cfg.user;
              Group = cfg.group;
              ExecStart = "${cfg.package}/bin/weed master -volumeSizeLimitMB ${toString cfg.master.volumeSizeLimitMB} -mdir=${cfg.master.dirPath} -port=${toString cfg.master.port} -metricsPort=${toString cfg.master.metricsPort} ${concatStringsSep " " cfg.master.extraArgs}";
              Restart = "on-failure";
              StateDirectory = "seaweedfs-master";
            };
          };
        })

        # Volume services - create a service for each volume instance
        (mkIf cfg.volume.enable (
          listToAttrs (
            map (
              volume:
              let
                diskTypeArg = if volume.diskType != null then "-disk=${volume.diskType}" else "";
              in
              nameValuePair "seaweedfs-volume-${volume.name}" {
                description = "SeaweedFS Volume Server (${volume.name})";
                after = [ "seaweedfs-master.service" ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "simple";
                  # User = cfg.user;
                  # Group = cfg.group;
                  User = "root"; # Volume operations typically need root privileges
                  Group = "root";
                  ExecStart = "${cfg.package}/bin/weed volume -max=${toString volume.max} ${diskTypeArg} -dir=${volume.dirPath} -port=${toString volume.port} -metricsPort=${toString volume.metricsPort} ${concatStringsSep " " volume.extraArgs}";
                  Restart = "on-failure";
                  # StateDirectory = "seaweedfs-volume-${volume.name}";
                };
              }
            ) cfg.volume.instances
          )
        ))

        # Filer service
        (mkIf cfg.filer.enable {
          "seaweedfs-filer" = {
            description = "SeaweedFS Filer Server";
            after = [
              "seaweedfs-master.service"
            ] ++ (map (vol: "seaweedfs-volume-${vol.name}.service") cfg.volume.instances);
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "simple";
              User = cfg.user;
              Group = cfg.group;
              ExecStart = "${cfg.package}/bin/weed filer -port=${toString cfg.filer.port} -metricsPort=${toString cfg.filer.metricsPort} ${concatStringsSep " " cfg.filer.extraArgs}";
              Restart = "on-failure";
              StateDirectory = "seaweedfs-filer";
            };
          };
        })

        # S3 gateway service
        (mkIf cfg.s3.enable {
          "seaweedfs-s3" = {
            description = "SeaweedFS S3 Gateway";
            after = [ "seaweedfs-filer.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "simple";
              User = cfg.user;
              Group = cfg.group;
              ExecStart = "${cfg.package}/bin/weed s3 -ip.bind=0.0.0.0 -port=${toString cfg.s3.port} -metricsPort=${toString cfg.s3.metricsPort} ${concatStringsSep " " cfg.s3.extraArgs}";
              Restart = "on-failure";
              StateDirectory = "seaweedfs-s3";
            };
          };
        })
      ];
    }))
    (mkIf cfg.mount.enable {
      # FUSE mount services - create a service for each mount point
      # create each mount point folder
      # TODO: below won't work if server is enabled (arrays won't merge)
      systemd.tmpfiles.rules = (
        map (mount: "d ${mount.mountPoint} 0770 ${cfg.user} ${cfg.group} - -") cfg.mount.instances
      );
      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        description = "SeaweedFS User";
        createHome = true;
        home = "/var/lib/seaweedfs";
      };

      users.groups.${cfg.group} = {
        name = cfg.group;
      };

      systemd.services = listToAttrs (
        map (
          mount:
          let
            collectionArg = if mount.collection != null then "-collection=${mount.collection}" else "";
            pathArg = if mount.path != null then "-filer.path=${mount.path}" else "";
          in
          nameValuePair "seaweedfs-mount-${mount.name}" {
            description = "SeaweedFS FUSE Mount (${mount.name})";
            after = [ "seaweedfs-filer.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "forking";
              User = "root"; # Mount operations typically need root privileges
              Group = "root";
              ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mount.mountPoint}";
              ExecStart = "${pkgs.bash}/bin/bash -c '${cfg.package}/bin/weed mount -filer=${mount.filerAddress} ${collectionArg} ${pathArg} -dir=${mount.mountPoint} ${concatStringsSep " " mount.extraArgs} &'";
              ExecStop = "${pkgs.utillinux}/bin/umount ${mount.mountPoint}";
              Restart = "on-failure";
            };
          }
        ) cfg.mount.instances
      );
    })
  ];

}
