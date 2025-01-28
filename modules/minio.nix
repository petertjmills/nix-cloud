{
  services.minio = {
    enable = true;
    browser = true;
    dataDir = "/data/minio";
    region = "milton-keynes";

  };

  networking.firewall.allowedTCPPorts = [
    9000
    9001
  ];
}
