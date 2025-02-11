{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.opentofu.withPlugins(
      ps: with ps; [
        incus
        hcloud
      ]
    ))
  ];
}
