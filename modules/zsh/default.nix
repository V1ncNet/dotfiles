{ pkgs, ... }:

{
  environment = {
    shells = with pkgs; [
      zsh
    ];
  };

  programs.zsh = {
    enable = true;
    enableSyntaxHighlighting = true;
  };
}
