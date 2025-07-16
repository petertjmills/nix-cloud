{
  config,
  pkgs,
  ...
}:

{
  imports = [
  ];

  networking.hostName = "cumulus";

  environment.systemPackages = [
    pkgs.git
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
      host  all      all     192.168.100.0/24   trust
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
  ];

}
