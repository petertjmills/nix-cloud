{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.financeTracker;
  financeTracker = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "finance-tracker-next";
    version = "0.0.1";

    src = builtins.fetchGit {
      url = "git@github.com:petertjmills/finance-tracker-next.git";
      ref = "main";
      rev = "c2c0e291d26fae026f003119eae9bfadb6707d34";
    };

    buildInputs = [
      pkgs.nodejs
    ];

    nativeBuildInputs = [
      pkgs.pnpm.configHook
    ];

    pnpmDeps = pkgs.pnpm.fetchDeps {
      inherit (finalAttrs) pname version src;
      hash = "sha256-8+MOzdiujjjjL6W016kJ718rv/OSetIfThuY2qAcaUo=";
    # hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    buildPhase = ''
      runHook preBuild

      pnpm build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp -r . $out/bin

      runHook postInstall
    '';

    meta = {
      description = "Personal Finance tracker";
    };
  });
in
{
  options = {
    services.financeTracker = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable foo.
        '';
      };

      env_file = mkOption {
        type = types.path;
        default = "/var/financetracker/.env";
        description = ''
          .env file for finance tracker build.
        '';
      };

      postgresServiceName = mkOption {
        type = types.str;
        default = "postgresql.service";
        description = ''
          Name of the postgres service.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.financeTracker = {
      description = "Finance Tracker Service";

      serviceConfig = {
        WorkingDirectory = "${financeTracker}/bin";
        ExecStartPre = "${financeTracker}/bin/node_modules/drizzle-kit/bin.cjs migrate";
        ExecStart = "${financeTracker}/bin/node_modules/next/dist/bin/next start";
        # Restart = "on-failure";
        EnvironmentFile = cfg.env_file;
      };

      wantedBy = [ "multi-user.target" ];
      wants = [ cfg.postgresServiceName ];
    };

    systemd.services.refreshTransactions = {
      description = "Refresh Transactions Service";
        script = ''
          ${pkgs.curl}/bin/curl "http://0.0.0.0:3000/api/refresh"
        ''; 
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };

      wantedBy = [ "multi-user.target" ];
      wants = [ "financeTracker.service" ];
    };

    systemd.timers.refreshTransactions = {
      description = "Refresh Transactions Timer";
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };

      wantedBy = [ "timers.target" ];
      wants = [ "refreshTransactions.service" ];
    };
  };
}
