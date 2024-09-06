{ pkgs, config, ... }:

{
  imports = (import ../../modules/home-manager);

  home = {
    username = "vincent";
    homeDirectory = "/Users/vincent";
    stateVersion = "24.05";

    packages = with pkgs; [
      direnv
      fzf
      gnupg
      zoxide
    ];

    file."${config.home.homeDirectory}/.gnupg/gpg-agent.conf".text = ''
      default-cache-ttl 600
      max-cache-ttl 7200
    '';
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

    gpg = {
      enable = true;
      homedir = "${config.home.homeDirectory}/.gnupg";
    };

    starship.settings.character = {
      success_symbol = "[▶](bold green)";
      error_symbol = "[▶](bold red)";
    };

    zsh = {
      profileExtra = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"

        export PATH="$PATH:/Users/vincent/Library/Application Support/JetBrains/Toolbox/scripts"
      '';

      shellAliases = {
        nixswitch = "darwin-rebuild switch --flake ~/src/vinado/dotfiles/.#";
      };

      envExtra = ''
        typeset -U path PATH
        path+=(~/.local/bin)

        JAVA_HOME="$(/usr/libexec/java_home -v 11)"
        VISUAL="$EDITOR"

        export PATH
      '';

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
        ];

        extraConfig = ''
          zstyle ':omz:plugins:nvm' lazy yes
        '';
      };
    };
  };
}
