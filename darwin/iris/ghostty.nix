{ pkgs, ... }:

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
    };
  };
}
