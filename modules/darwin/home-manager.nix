{ inputs, pkgs, ... }:
let
  user = "petermills";
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];

  users.users.${user} = {
    name     = "${user}";
    home     = "/Users/${user}";
    isHidden = false;
    shell    = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = [
      "displaylink"
      "zen"
      "little-snitch"
      "yaak"
      "obsidian"
      "beekeeper-studio"
      "google-chrome"
      "discord"
      "daisydisk"
      "ghostty"
    ];
    masApps = {
      "WhatsApp Messenger" = 310633997;
      "Logic Pro" = 634148309;
      "wireguard" = 1451685025;
    };
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["spotify", "raycast"];

  home-manager.users.${user} = {
    home.packages = [
      pkgs.spotify
      pkgs.raycast
      pkgs.blender
      pkgs.wireshark
      # pkgs.nixfmt-rfc-style
      # pkgs.nixd
    ];

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
      zed-editor = {
        enable = true;
        extensions = [
          "dockerfile"
          "sql"
          "astro"
          "nix"
          "log"
          "vscode-dark-modern"
        ];
        # Not available til 25.05
        extraPackages = [
          pkgs.nixfmt-rfc-style
          pkgs.nixd
        ];
        installRemoteServer = false;
        userSettings = {
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
              model = "claude-sonnet-4-thinking-latest";
            };
            version = "2";
          };
          vim_mode = true;
          ui_font_size = 16;
          buffer_font_size = 13;
          buffer_font_family = "SF Mono";
          theme = {
            mode = "system";
            light = "VSCode Dark Modern";
            dark = "One Dark";
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
      git = {
        enable = true;
        userEmail = "ptjm8422@gmail.com";
        userName = "petertjmills";
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
}
