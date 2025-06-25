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
    programs = {
      direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
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
          ];
          theme = "dieter";
        };
      };
      git = {
        enable = true;
        userEmail = "ptjm8422@gmail.com";
        userName = "petertjmills";
      };
    };
    home.stateVersion = "24.11";
  };
}
