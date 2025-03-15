{...}:
{
  imports = [
    ../machine/home-server.nix
    ../modules/zsh.nix
    ../modules/incus-server.nix
  ];

  services.incus-server = {
    enable = true;
    ip.address = "192.168.86.192";
    ip.internalSubnet = "10.0.0.1/24";
    defaultGateway = "192.168.86.1";
    images = [
      {
        name = "nixos-vm-base";
        module = ../images/incus-vm-base;
        script = buildOutput: ''
          ${pkgs.incus}/bin/incus image import --alias ${buildOutput.name} \
            ${buildOutput.build.metadata}/tarball/nixos-system-x86_64-linux.tar.xz \
            ${buildOutput.build.qemuImage}/nixos.qcow2
        '';
      }
      {
        name = "nixos-lxc-base";
        module = ../images/incus-lxc-base;
        script = buildOutput: ''
          ${pkgs.incus}/bin/incus image import --alias ${buildOutput.name} \
            ${buildOutput.build.metadata}/tarball/nixos-system-x86_64-linux.tar.xz \
            ${buildOutput.build.squashfs}/nixos-lxc-image-x86_64-linux.squashfs
        '';
      }
    ];
  };
}
