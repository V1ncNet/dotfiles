{ lib, ... }:

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

    # The app is installed as a Homebrew cask, which shows up properly in
    # Spotlight and keeps itself up to date
    package = null;

    settings = {
      clipboard-read = "allow";
      confirm-close-surface = false;
      copy-on-select = "clipboard";
      font-family = "Hack Nerd Font Mono";
      # Turns text black or white below a WCAG contrast of 2, e.g. htop's
      # black on green/cyan header and selection in the dark theme, while
      # leaving moderately low-contrast colors untouched
      minimum-contrast = 2;
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
