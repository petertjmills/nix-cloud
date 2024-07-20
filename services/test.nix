{ pkgs, config, lib, ... }:

with lib;

let
  testcfg = config.services.testService;
in {
  options = {
    services.testService = {
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

  config = mkIf testcfg.enable {
    systemd.services.testService = {
      description = "Simple Test Service";

      serviceConfig = {
        ExecStart = "${pkgs.bash}/bin/bash -c 'echo \"${testcfg.logText}\" >> /var/log/test_service.log'";
        Restart = "on-failure";
      };

      wantedBy = [ "multi-user.target" ];
    };
  };
}
