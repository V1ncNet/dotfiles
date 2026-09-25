{ pkgs, config, ... }:

{
  imports = (import ../modules/home-manager);

  home = {
    packages = with pkgs; [
      fzf
      zoxide
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  programs = {
    home-manager.enable = true;
    dircolors.enable = true;
    direnv.enable = true;
    fzf.enable = true;
    command-not-found.enable = true;
    zoxide.enable = true;

    zsh = {
      envExtra = ''
        typeset -U path PATH
        path+=(~/.local/bin)

        VISUAL="$EDITOR"

        export PATH
      '';
    };
  };
}
