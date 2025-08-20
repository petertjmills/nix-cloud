{ inputs, pkgs, ... }:
let
  users = import "${inputs.secrets}/user.nix";
  user = users.darwin.username;
in
{
  imports = [
    ../home/darwin
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    user = user;
    taps = {
      "homebrew/core" = inputs.homebrew-core;
      "homebrew/cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
  };

  # services.tailscale.enable = true;
  # services.tailscale.overrideLocalDns = true;
  # networking.knownNetworkServices = [
  #   "Wi-Fi"
  #   "Ethernet"
  # ];

  power.sleep.display = "never";

  nix = {
    package = pkgs.nix;
    channel.enable = false;
    settings = {
      trusted-users = [
        "@admin"
        "${user}"
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
    # Turn this on to make command line easier
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # # Allow to build for linux
  # nix.linux-builder = {
  #   enable = true;
  #   systems = [
  #     "x86_64-linux"
  #     # "aarch64-linux"
  #   ];
  #   package = pkgs.darwin.linux-builder-x86_64;
  #   ephemeral = true;
  #   maxJobs = 6;
  #   config = {
  #     virtualisation = {
  #       cores = 6;
  #       darwin-builder = {
  #         diskSize = 50 * 1024;
  #         memorySize = 8 * 1024;
  #         hostPort = 31022 + 12;
  #       };
  #     };
  #     # We have to emulate aarch64 on x86 qemu, see https://github.com/golang/go/issues/69255
  #     # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  #   };
  # };
  nix.linux-builder = {
    enable = true;
    systems = [
      "aarch64-linux"
    ];
    package = pkgs.darwin.linux-builder;
    ephemeral = true;
    maxJobs = 6;
    config = {
      virtualisation = {
        cores = 6;
        darwin-builder = {
          diskSize = 50 * 1024;
          memorySize = 8 * 1024;
        };
      };
    };
  };

  system = {
    # Turn off NIX_PATH warnings now that we're using flakes
    checks.verifyNixPath = false;
    stateVersion = 5;
    primaryUser = user;
    defaults.dock.autohide = true;
  };
}
