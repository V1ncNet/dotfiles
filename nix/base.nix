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
        # Also for non-interactive shells, e.g. commands run via SSH
        if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        fi

        typeset -U path PATH
        path+=(~/.local/bin)

        VISUAL="$EDITOR"

        export PATH
      '';
    };
  };
}
