{ pkgs, lib, ... }:

let
  claude = import ../../themes/claude.nix;

  toGhostty = theme: {
    palette = lib.imap0 (i: color: "${toString i}=${color}") theme.palette;
    background = theme.background;
    foreground = theme.foreground;
    cursor-color = theme.cursor;
    selection-background = theme.selectionBackground;
    selection-foreground = theme.selectionForeground;
  };
in
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;

    settings = {
      auto-update = "off";
      clipboard-read = "allow";
      confirm-close-surface = false;
      copy-on-select = "clipboard";
      font-family = "Hack Nerd Font Mono";
      quit-after-last-window-closed = true;
      shell-integration-features = "no-cursor";
      theme = "light:Claude Light,dark:Claude Dark";
    };

    themes = {
      "Claude Dark" = toGhostty claude.dark;
      "Claude Light" = toGhostty claude.light;
    };
  };
}
