{ pkgs, lib, config, ... }:

let
  taskThemes = "${config.programs.taskwarrior.package}/share/doc/task/rc";
  taskTheme = "${config.xdg.stateHome}/task/theme";
in
{
  imports = (import ../../modules/home-manager) ++ [ ./ghostty.nix ];

  home = {
    username = "vincent";
    homeDirectory = "/Users/vincent";
    stateVersion = "25.05";

    packages = with pkgs; [
      direnv
      fzf
      gnupg
      rustup
      zoxide
    ];

    file."${config.home.homeDirectory}/.gnupg/gpg-agent.conf".text = ''
      default-cache-ttl 600
      max-cache-ttl 7200
    '';

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
    ];

    sessionVariables = {
      DIAGRAM_DITAA_CLASSPATH = "${pkgs.ditaa}/lib/ditaa.jar";
      HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
      HOMEBREW_PREFIX = "/opt/homebrew";
      HOMEBREW_REPOSITORY = "/opt/homebrew";
      JAVA_HOME = "/Library/Java/JavaVirtualMachines/temurin-25.jdk/Contents/Home";
    };
  };

  programs = {
    home-manager.enable = true;
    dircolors.enable = true;
    direnv.enable = true;
    fzf.enable = true;
    command-not-found.enable = true;

    zoxide = {
      enable = true;
      options = [
        "--cmd cd"
      ];
    };

    git = {
      signing = {
        signByDefault = true;
        key = "6FD477B1";
      };
    };

    taskwarrior = {
      enable = true;
      package = pkgs.taskwarrior3;
      extraConfig = "include ${taskTheme}";
    };

    gpg = {
      enable = true;
      homedir = "${config.home.homeDirectory}/.gnupg";
    };

    starship.settings.character = {
      success_symbol = "[▶](bold green)";
      error_symbol = "[▶](bold red)";
    };

    zsh = {
      dotDir = "${config.home.homeDirectory}/.config/zsh";

      envExtra = ''
        # Append Homebrew so that Nix takes precedence
        typeset -U path
        path+=(/opt/homebrew/bin /opt/homebrew/sbin)
      '';

      initContent = ''
        appearance() {
          [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == Dark ]] && echo dark || echo light
        }

        task() {
          ln -sfn "${taskThemes}/$(appearance)-16.theme" "${taskTheme}"
          command task "$@"
        }
      '';

      shellAliases = {
      };

      oh-my-zsh = {
        plugins = [
          "ansible"
          "brew"
          "gpg-agent"
          "mvn"
          "node"
          "npm"
          "nvm"
          "pip"
          "taskwarrior"
        ];

        extraConfig = ''
          zstyle ':omz:plugins:nvm' lazy yes
        '';
      };
    };
  };

  home.activation.taskwarriorTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$(dirname "${taskTheme}")"
    run ln -sfn "${taskThemes}/dark-16.theme" "${taskTheme}"
  '';
}
