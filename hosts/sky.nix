{
  pkgs,
  ipPool,
  config,
  ...
}:
let
  ip = ipPool 0;
in
{
  imports = [
    ../machines/home-server.nix
    ../modules/zsh.nix
    ../modules/incus-server.nix
    ../modules/dns.nix
  ];

  networking.hostName = "sky";
  dns.domains = [
    {
      name = "${config.networking.hostName}.internal";
      ip = ip.internalIp;
    }
    {
      name = "${config.networking.hostName}.lan";
      ip = ip.address;
    }
  ];

  services.incusServer = {
    enable = true;
    ip.address = ip.address;
    ip.internalSubnet = ip.internalSubnet;
    defaultGateway = ip.defaultGateway;
    images = [
      {
        name = "nixos-vm-base";
        module = ../images/incus-vm-base.nix;
        script = buildOutput: ''
            echo "Deleting old image"
          ${pkgs.incus}/bin/incus image delete ${buildOutput.name}

            echo "Importing new image"
          ${pkgs.incus}/bin/incus image import --alias ${buildOutput.name} \
            ${buildOutput.build.metadata}/tarball/nixos-system-x86_64-linux.tar.xz \
            ${buildOutput.build.qemuImage}/nixos.qcow2
        '';
      }
      {
        name = "nixos-lxc-base";
        module = ../images/incus-lxc-base.nix;
        script = buildOutput: ''
          echo "Deleting old image"
          ${pkgs.incus}/bin/incus image delete ${buildOutput.name}

          echo "Importing new image"
          ${pkgs.incus}/bin/incus image import --alias ${buildOutput.name} \
            ${buildOutput.build.metadata}/tarball/nixos-system-x86_64-linux.tar.xz \
            ${buildOutput.build.squashfs}/nixos-lxc-image-x86_64-linux.squashfs
        '';
      }
    ];
  };
}
