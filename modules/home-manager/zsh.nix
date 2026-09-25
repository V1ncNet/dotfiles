{ pkgs, ... }:

{
  home.packages = [ pkgs.zsh pkgs.oh-my-zsh ];

  programs.zsh = {
    enable = true;

    history = {
      ignoreAllDups = true;
      share = true;
    };

    localVariables = {
      HIST_STAMPS = "yyyy-mm-dd";
      PYTHON_AUTO_VRUN = true;
      PYTHON_VENV_NAME = ".venv";
    };

    shellAliases = {
      uuidgen = "uuidgen | tr \"[:upper:]\" \"[:lower:]\" | tr -d \\\\n";
      kw = "date +%W";
    };

    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "v1.3.0";
          sha256 = "sha256-8atbysoOyCBW2OYKmdc91x9V/Mk3eyg3hvzvhJpQ32w=";
        };
      }
      {
        name = "zsh-completions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-completions";
          rev = "0.36.0";
          sha256 = "sha256-XCSC7DyhfnxzKjtbdsu7/pyw8eoVLPdthEoFZ8rBAyo=";
        };
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.7.1";
          sha256 = "sha256-vpTyYq9ZgfgdDsWzjxVAE7FZH4MALMNZIFyEOBLm5Qo=";
        };
      }
    ];

    oh-my-zsh = {
      enable = true;

      plugins = [
        "copyfile"
        "copypath"
        "cp"
        "docker"
        "docker-compose"
        "encode64"
        "extract"
        "git"
        "python"
        "sudo"
      ];

      extraConfig = ''
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
        zstyle ':completion:*:*:docker:*' option-stacking yes
        zstyle ':completion:*:*:docker-*:*' option-stacking yes
        zstyle ':completion::complete:*' gain-privileges 1
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' menu no
      '';
    };

    historySubstringSearch.enable = true;
    syntaxHighlighting.enable = true;
  };

  programs.dircolors.enableZshIntegration = true;
  programs.direnv.enableZshIntegration = true;
  programs.fzf.enableZshIntegration = true;
  programs.zoxide.enableZshIntegration = true;
}
