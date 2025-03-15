{ inputs, ... }:
{
  environment.systemPackages = [
    inputs.nixvim.packages.x86_64-linux.default # TODO: this would be better as a module rather than a package like disko

  ];
}
