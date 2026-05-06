{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.used-teslas-website;
in
{
  options.services.used-teslas-website = {
    enable = mkEnableOption "Used Teslas UK website";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ../pkgs/website.nix { };
      defaultText = literalExpression "pkgs.callPackage ../pkgs/website.nix { }";
      description = "The used-teslas-website package to use.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "The host address to bind to.";
    };

    port = mkOption {
      type = types.port;
      default = 4321;
      description = "The port to listen on.";
    };

    user = mkOption {
      type = types.str;
      default = "used-teslas-website";
      description = "User account under which the website runs.";
    };

    group = mkOption {
      type = types.str;
      default = "used-teslas-website";
      description = "Group under which the website runs.";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Environment file containing additional environment variables.
        This file should contain KEY=VALUE pairs, one per line.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.used-teslas-website = {
      description = "Used Teslas UK Website";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        HOST = cfg.host;
        PORT = toString cfg.port;
        NODE_ENV = "production";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/${cfg.package.pname}";
        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ ];

        # Load environment file if specified
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;
      };
    };

    users.users.${cfg.user} = mkIf (cfg.user == "used-teslas-website") {
      isSystemUser = true;
      group = cfg.group;
      description = "Used Teslas website service user";
    };

    users.groups.${cfg.group} = mkIf (cfg.group == "used-teslas-website") { };
  };
}
