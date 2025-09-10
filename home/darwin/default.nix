{
  inputs,
  pkgs,
  lib,
  unstableDarwin,
  unfreeDarwinPkgs,
  ...
}:
let
  users = import "${inputs.secrets}/user.nix";
  user = users.darwin.username;
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ./dock.nix
    ../default.nix
  ];

  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
    casks = [
      "zen"
      "little-snitch@5"
      "yaak"
      "obsidian"
      "beekeeper-studio"
      "google-chrome"
      "discord"
      "daisydisk"
      "ghostty"
      "spotify"
      "focusrite-control"
      "displaylink"
      "launchcontrol"
      "tailscale"
      "ollama"
      "thunderbird"
      "calibre"
    ];
    brews = [ "ollama" ];

    masApps = {
      "WhatsApp Messenger" = 310633997;
      "Logic Pro" = 634148309;
      "wireguard" = 1451685025;
    };
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "raycast"
    ];

  home-manager.users.${user} = {
    home.packages = [
      pkgs.raycast
      pkgs.blender
      pkgs.wireshark
      pkgs.nixfmt-rfc-style
      pkgs.nixd
      pkgs.nixos-rebuild
      # pkgs.tailscale
      unfreeDarwinPkgs.vscode
    ];

    programs = {
      zed-editor = {
        enable = true;
        package = unstableDarwin.zed-editor;
        extensions = [
          "dockerfile"
          "sql"
          "astro"
          "nix"
          "log"
          "vscode-dark-modern"
        ];
        extraPackages = [
          pkgs.nixfmt-rfc-style
          pkgs.nixd
        ];
        installRemoteServer = false;
        userSettings = {
          terminal.scrollbar.show = false;
          edit_predictions = {
            mode = "subtle";
            copilot = {
              proxy = null;
              proxy_no_verify = null;
            };
            enabled_in_text_threads = false;
          };
          features = {
            edit_prediction_provider = "zed";
          };
          terminal = {
            dock = "bottom";
          };
          agent = {
            always_allow_tool_actions = true;
            default_profile = "ask";
            default_model = {
              provider = "zed.dev";
              model = "claude-sonnet-4";
            };
            version = "2";
          };
          vim_mode = true;
          ui_font_size = 16;
          buffer_font_size = 14;
          buffer_font_family = "SF Mono";
          theme = {
            mode = "dark";
            # light = "VSCode Dark Modern";
            light = "One Light";
            dark = "VSCode Dark Modern";
          };
          vim = {
            toggle_relative_line_numbers = true;
          };
          lsp = {
            nixd = {
              settings = {
                diagnostic = {
                  suppress = [
                    "sema-extra-with"
                  ];
                };
              };
            };
          };
          languages = {
            Nix = {
              language_servers = [
                "nixd"
                "!nil"
              ];
              formatter = {
                external = {
                  command = "nixfmt";
                };
              };
              tab_size = 2;
            };
          };
        };
      };
      ghostty = {
        enable = true;
        package = null;
        enableZshIntegration = true;
        settings = {
          background-opacity = 0.7;
          background-blur-radius = 50;
          theme = "LiquidCarbonTransparent";
          font-family = "SF Mono";
        };
      };
    };
    home.stateVersion = "24.11";
  };

  local.dock = {
    enable = true;
    username = user;
    entries = [
      { path = "/Applications/Zen.app/"; }
      { path = "${unstableDarwin.zed-editor}/Applications/Zed.app"; }
      { path = "/Applications/Spotify.app/"; }
      { path = "/Applications/Ghostty.app/"; }
      { path = "/System/Applications/Messages.app/"; }
      { path = "/Applications/WhatsApp.app/"; }
      { path = "/System/Applications/Mail.app/"; }
      { path = "/System/Applications/Calendar.app/"; }
      { path = "/System/Applications/Reminders.app/"; }
      { path = "/System/Applications/Utilities/Activity Monitor.app/"; }
      { path = "/System/Applications/System Settings.app/"; }
    ];
  };
}
