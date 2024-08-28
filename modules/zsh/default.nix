{ pkgs, ... }:

{
  environment = {
    loginShell = pkgs.zsh;

    shells = with pkgs; [
      zsh
    ];
  };

  programs.zsh = {
    enable = true;
    enableSyntaxHighlighting = true;
  };
}
