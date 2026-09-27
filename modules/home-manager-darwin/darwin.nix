{ pkgs, lib, ... }:

{
  home = {
    packages = [ pkgs.fnm ];

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
    ];
  };

  programs = {
    starship.settings.character = {
      success_symbol = "[▶](bold green)";
      error_symbol = "[▶](bold red)";
    };

    zsh.initContent = ''
      eval "$(${lib.getExe pkgs.fnm} env --use-on-cd --version-file-strategy=recursive --shell zsh)"
    '';
  };
}
