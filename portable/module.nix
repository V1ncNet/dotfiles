{
  home = {
    username = "vincent";
    homeDirectory = "/__HOME__";
    stateVersion = "25.05";

    file."Library/Fonts/.home-manager-fonts-version".enable = false;
  };

  programs = {
    dircolors.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = false;
    };

    fzf.enable = true;
    zoxide.enable = true;

    git.settings.include.path = "~/.config/git/local";

    zsh.package = null;

    zsh.envExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"

      typeset -U path PATH
      path+=(~/.local/bin)
    '';
  };
}
