{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -lah";
    };

    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "dieter";
    };
  };
  users.defaultUserShell = pkgs.zsh;

}
