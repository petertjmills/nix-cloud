hostPkgs:
{ pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];
  networking.hostName = "qemuvm";
  virtualisation = {
    memorySize = 2048;
    cores = 2;
    host.pkgs = hostPkgs;
    graphics = false;
    # forwardPorts = [
    #   {
    #     from = "host";
    #     host.port = 2222;
    #     guest.port = 22;
    #   }
    # ];
    diskImage = null;
  };

  users.users.nixos = {
    isNormalUser = true;
    password = "nixos";
    extraGroups = [ "wheel" ];
  };
  services.getty.autologinUser = "nixos";
  services.openssh.enable = true;
  system.stateVersion = "24.05";
}
