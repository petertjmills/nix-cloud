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
      # "tailscale"
      "thunderbird"
      "calibre"
      "blender"
    ];

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
      # pkgs.blender
      pkgs.wireshark
      pkgs.nixfmt-rfc-style
      pkgs.nixd
      pkgs.nixos-rebuild
      # pkgs.tailscale
      unfreeDarwinPkgs.vscode
      unstableDarwin.librespot
      pkgs.nodejs
    ];

    # xdg.configFile =
    #   (lib.mapAttrs'
    #     (
    #       name: content:
    #       lib.nameValuePair "opencode/skills/${name}/SKILL.md" (
    #         if lib.isPath content then { source = content; } else { text = content; }
    #       )
    #     )
    #     {
    #       "frontend-design" = ../../ai/skills/frontend-design.md;
    #     }
    #   )
    #   // (lib.mapAttrs'
    #     (
    #       name: content:
    #       lib.nameValuePair "opencode/agents/${name}.md" (
    #         if lib.isPath content then { source = content; } else { text = content; }
    #       )
    #     )
    #     {
    #       "architect" = ../../ai/agents/architect.md;
    #       "code-reviewer" = ../../ai/agents/code-reviewer.md;
    #       "code-reviewerer" = ../../ai/agents/code-reviewerer.md;
    #       "developer" = ../../ai/agents/developer.md;
    #       "repo-scout" = ../../ai/agents/repo-scout.md;
    #     }
    #   );

    programs = {
      opencode = {
        enable = true;
        package = inputs.opencode.packages."aarch64-darwin".default;
        rules = ../../ai/rules.md;
        skills = ../../ai/skills;
        agents = ../../ai/agents;
        settings.agent.explore.disable = true;
      };

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
          "context_servers".shadcn-local = {
            command = "npx";
            args = [
              "shadcn@latest"
              "mcp"
            ];
          };

          # terminal.scrollbar.show = false;
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
            play_sound_when_agent_done = true;
            default_profile = "ask";
            default_model = {
              provider = "zed.dev";
              model = "claude-opus-4.5";
            };
            profiles.ask = {
              name = "Ask";
              tools.web_search = false;
              tools.fetch = false;
            };
            profiles.write = {
              name = "Write";
              tools.web_search = false;
              tools.fetch = false;
            };
            profiles.shadcn = {
              name = "Shadcn";
              tools.web_search = false;
              tools.fetch = true;
              tools.diagnostics = true;
              tools.find_path = true;
              tools.grep = true;
              tools.list_directory = true;
              tools.open = true;
              tools.read_file = true;
              tools.thinking = true;
            };
            profiles.shadcn-write = {
              name = "Shadcn write";
              tools.web_search = false;
              tools.fetch = true;
              tools.diagnostics = true;
              tools.find_path = true;
              tools.grep = true;
              tools.list_directory = true;
              tools.open = true;
              tools.read_file = true;
              tools.thinking = true;
              tools.copy_path = true;
              tools.create_directory = true;
              tools.delete_path = true;
              tools.edit_file = true;
              tools.move_path = true;
              tools.terminal = true;
            };
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
