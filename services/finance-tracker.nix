{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.financeTracker;
in {
  options = {
    services.financeTracker = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable foo.
        '';
      };

      logText = mkOption {
        type = types.str;
        default = "Test service is running";
        description = ''
          Text to log.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.testService = {
      description = "Finance Tracker Service";

      serviceConfig = {
        ExecStart = "${pkgs.finance-tracker-next}/bin/nixtest";
        Restart = "on-failure";
      };

      wantedBy = [ "multi-user.target" ];
    };
  };
}
