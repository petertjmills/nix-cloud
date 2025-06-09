{
  config,
  pkgs,
  ipPool,
  ...
}:
let
  ip = ipPool 1;
in
{
  imports = [
    ../machines/incus-container.nix
    ../modules/zsh.nix
    ../modules/opentofu.nix
    ../modules/home-manager.nix
  ];

  networking.hostName = "cumulus";
  ip = ip.internalIp;
  lanIp = ip.address;

  terranix.resource."incus_instance"."${config.networking.hostName}" = {
    config."security.nesting" = true;
    limits = {
      cpu = 4;
      memory = "4GiB";
    };
    device = [
      {
        name = "root";
        type = "disk";
        properties = {
          path = "/";
          pool = "lvm";
          size = "50GiB";
        };
      }
    ];
  };

  environment.systemPackages = [
    pkgs.nixd
    pkgs.nixfmt-rfc-style
    pkgs.incus
    pkgs.git
    pkgs.just
    pkgs.sops
    pkgs.go
    pkgs.gopls
  ];
  documentation.nixos.enable = true;
  documentation.man.enable = true;


  # postgresql dev database
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
      host  all      all     192.168.86.0/24   trust
      host  all      all     10.100.0.8/32   trust
      host  all      all     10.0.0.3/32   trust
      host  all      all     10.0.0.2/32   trust
      #host  all      all     192.168.86.231/32   trust
      # ipv6
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE metachroma_dev WITH LOGIN PASSWORD 'metachroma_dev' CREATEDB;
      CREATE DATABASE metachroma_dev;
      GRANT ALL PRIVILEGES ON DATABASE metachroma_dev TO metachroma_dev;
      ALTER SCHEMA public OWNER TO metachroma_dev;
    '';
  };
  networking.firewall.allowedTCPPorts = [
    5432
    8011
    4321
    25
  ];
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];
  nix.settings.extra-platforms = [
    "x86_64-linux"
    "aarch64-linux"
  ];
}
