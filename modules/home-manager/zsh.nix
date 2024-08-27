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
      ZOXIDE_CMD_OVERRIDE = "cd";
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
          rev = "v1.1.2";
          sha256 = "sha256-Qv8zAiMtrr67CbLRrFjGaPzFZcOiMVEFLg1Z+N6VMhg";
        };
      }
      {
        name = "zsh-completions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-completions";
          rev = "0.35.0";
          sha256 = "sha256-GFHlZjIHUWwyeVoCpszgn4AmLPSSE8UVNfRmisnhkpg";
        };
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.7.0";
          sha256 = "sha256-KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w";
        };
      }
      {
        name = "zsh-syntax-highlighting";
        file = "zsh-syntax-highlighting.sh";
        src = pkgs.fetchFromGitHub {
          owner = "dracula";
          repo = "zsh-syntax-highlighting";
          rev = "09c89b6";
          sha256 = "sha256-JrSKx8qHGAF0DnSJiuKWvn6ItQHvWpJ5pKo4yNbrHno";
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
