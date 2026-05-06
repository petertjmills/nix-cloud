{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  users = import "${inputs.secrets}/user.nix";
  user = users.darwin.username;
in
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.${user} = {
    home.packages = [
      pkgs.pirate-get
      pkgs.transmission_4
    ];
    xdg.configFile."pirate-get" = {
      enable = true;
      source = (pkgs.formats.toml { }).generate "pirate-get" {
        "Search"."total-results" = 5;
        "Misc".transmission = true;
        "Misc"."transmission-endpoint" = "sky:9091";
      };
    };
    programs = {
      direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
        silent = true;
        config = {
          load_dotenv = true;
        };
      };
      zsh = {
        enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;

        shellAliases = {
          ll = "ls -lah";
        };

        oh-my-zsh = {
          enable = true;
          plugins = [
            "git"
            "direnv"
            "jj"
          ];
          custom = "${./zsh-custom}";
          theme = "dieter-custom";
        };
      };
      git = {
        enable = true;
        settings.user.email = "ptjm8422@gmail.com";
        settings.user.name = "petertjmills";
      };
      jujutsu = {
        enable = true;
        settings.user = {
          email = "ptjm8422@gmail.com";
          name = "petertjmills";
        };
      };
    };
    home.stateVersion = "24.11";
  };
}
