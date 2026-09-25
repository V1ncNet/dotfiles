{ pkgs, ... }:

{
  environment = {
    shells = with pkgs; [
      zsh
    ];
  };

  programs.zsh = {
    enable = true;

    # Oh My Zsh, Starship and Home Manager take care of these
    enableBashCompletion = false;
    enableGlobalCompInit = false;
    promptInit = "";
  };
}
