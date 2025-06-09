{
  config,
  pkgs,
  ipPool,
  ...
}:
let
  ip = ipPool 4;
in
{
  imports = [
    ../machines/incus-container.nix
    ../modules/seaweedfs.nix
  ];

  networking.hostName = "cumulonimbus";
  ip = ip.internalIp;
  lanIp = ip.address;
  dns.domains = [
    {
      name = "${config.networking.hostName}.internal";
      ip = ip.internalIp;
    }
    {
      name = "${config.networking.hostName}.lan";
      ip = ip.address;
    }
  ];

  terranix.resource."incus_instance"."${config.networking.hostName}" = {
    config."security.nesting" = true;
    limits = {
      cpu = "1";
      memory = "4GiB";
    };

    device = [
      {
        name = "zfs_storage";
        type = "disk";
        properties = {
          pool = "tank";
          source = "zfs_tank_1tb";
          path = "/zfs_data";
        };
      }
      {
        name = "lvm_storage";
        type = "disk";
        properties = {
          pool = "lvm";
          source = "lvm_500gb";
          path = "/lvm_data";
        };
      }
    ];
  };

  services.seaweedfs = {
    enable = true;
    enableServer = true;
    package = pkgs.callPackage ../packages/seaweedfs.nix { };
  };
  monitoring.prometheusScrapeConfigs = [
    {
      job_name = "seaweedfs";
      static_configs = [
        {
          targets = [
            "${config.networking.hostName}.internal:29333"
            "${config.networking.hostName}.internal:28080"
            "${config.networking.hostName}.internal:28081"
            "${config.networking.hostName}.internal:28888"
            "${config.networking.hostName}.internal:28333"
          ];
        }
      ];
    }
  ];

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        # "dns hostname" = "cumulonimbus.internal";
        "name resolve order" = "bcast lmhosts host wins";
        "security" = "user";
        #"use sendfile" = "yes";
        #"max protocol" = "smb2";
        # note: localhost is the ipv6 localhost ::1
        # "hosts allow" = "192.168.0. 127.0.0.1 10.0.0. localhost";
        # "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "log level" = 10;
      };
      "public" = {
        "path" = "/zfs_data/smb";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "root";
        "force group" = "root";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    445
    139
  ];

  swapDevices = [
    {
      device = "/swapfile";
      size = 4096;
    }
  ];

}
