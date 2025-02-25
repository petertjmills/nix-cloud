{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.seaweedfs
  ];

  networking.firewall = {
    allowedTCPPorts = [
      9333
      19333
      8080
      8081
      18080
      8888
      18888
      8333
    ];
    allowedUDPPorts = [
      9333
      19333
      8080
      8081
      18080
      8888
      18888
      8333
    ];
  };

  users.users.seaweedfs = {
    isSystemUser = true;
    group = "seaweedfs";
    description = "SeaweedFS User";
    createHome = true;
    home = "/var/lib/seaweedfs";
  };

  users.groups.seaweedfs = {
    name = "seaweedfs";
  };

  systemd.tmpfiles.rules = [
    "d /lvm_data/seaweedfs/master 0770 seaweedfs seaweedfs - -"
    "d /zfs_data/seaweedfs/volumes 0770 seaweedfs seaweedfs - -"
    "d /lvm_data/seaweedfs/volumes 0770 seaweedfs seaweedfs - -"
    "d /etc/seaweedfs 0770 seaweedfs seaweedfs - -"
    "d /lvm_data/seaweedfs/filerldb2 0770 seaweedfs seaweedfs - -"
    "d /data 0770 seaweedfs seaweedfs - -" # Permissions for /data
  ];
  environment.etc."seaweedfs/filer.toml".text = ''
    [filer.options]
      recursive_delete = false

    [leveldb2]
      enabled = true
      dir = "/lvm_data/seaweedfs/filerldb2"
  '';

  systemd.services = {
    seaweedfs-master = {
      description = "SeaweedFS Master Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "seaweedfs";
        Group = "seaweedfs";
        ExecStart = "${pkgs.seaweedfs}/bin/weed master -volumeSizeLimitMB 1000 -mdir=/lvm_data/seaweedfs/master";
        Restart = "on-failure";
        StateDirectory = "seaweedfs-master";
      };
    };

    seaweedfs-volume-zfs-lvm = {
      description = "SeaweedFS Volume Server (ZFS/LVM)";
      after = [ "seaweedfs-master.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "seaweedfs";
        Group = "seaweedfs";
        ExecStart = "${pkgs.seaweedfs}/bin/weed volume -max=0 -disk=zfs,lvm -dir=/zfs_data/seaweedfs/volumes,/lvm_data/seaweedfs/volumes";
        Restart = "on-failure";
        StateDirectory = "seaweedfs-volume-zfs-lvm";
      };
    };

    seaweedfs-volume-root = {
      description = "SeaweedFS Volume Server (Root)";
      after = [ "seaweedfs-volume-zfs-lvm.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "seaweedfs";
        Group = "seaweedfs";
        ExecStart = "${pkgs.seaweedfs}/bin/weed volume -max=0 -dir=/data -port 8081";
        Restart = "on-failure";
        StateDirectory = "seaweedfs-volume-root";
      };
    };

    seaweedfs-filer = {
      description = "SeaweedFS Filer Server";
      after = [ "seaweedfs-volume-data.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "seaweedfs";
        Group = "seaweedfs";
        ExecStart = "${pkgs.seaweedfs}/bin/weed filer";
        Restart = "on-failure";
        StateDirectory = "seaweedfs-filer";
      };
    };

    seaweedfs-s3 = {
      description = "SeaweedFS S3 Gateway";
      after = [ "seaweedfs-filer.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "seaweedfs";
        Group = "seaweedfs";
        ExecStart = "${pkgs.seaweedfs}/bin/weed s3 -ip.bind 0.0.0.0";
        Restart = "on-failure";
        StateDirectory = "seaweedfs-s3";
      };
    };
  };
}
