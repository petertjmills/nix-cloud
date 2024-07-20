{ pkgs, ... }:
{
  services.testService = {
    enable = true;
    description = "Simple Test Service";

    serviceConfig = {
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo \"Test service is running\" >> /var/log/test_service.log'";
      Restart = "on-failure";
    };

    wantedBy = [ "multi-user.target" ];
  };
}
