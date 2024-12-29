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
      rustup
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
      '';

      envExtra = ''
        JAVA_HOME="$(/usr/libexec/java_home -v 21)"
        CPPFLAGS="-I/opt/homebrew/opt/openjdk@11/include -I/opt/homebrew/opt/openjdk@17/include -I/opt/homebrew/opt/openjdk@21/include -I/opt/homebrew/opt/openjdk/include"

        path+=$HOME/.local/bin
        path+=$HOME/Library/Application\ Support/JetBrains/Toolbox/scripts
      '';

      shellAliases = {
        nixswitch = "darwin-rebuild switch --flake ~/src/vinado/dotfiles/.#";
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
}
