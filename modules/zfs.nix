{pkgs, ...}: {
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "tank" ];
  networking.hostId = "d0a95792";
  environment.systemPackages = [
    pkgs.zfs
  ];
}
