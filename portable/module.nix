{
  home = {
    username = "vincent";
    homeDirectory = "/__HOME__";
    stateVersion = "25.05";

    file."Library/Fonts/.home-manager-fonts-version".enable = false;
  };

  programs = {
    direnv.nix-direnv.enable = false;

    git.settings.include.path = "~/.config/git/local";

    zsh.package = null;

    zsh.profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';
  };
}
