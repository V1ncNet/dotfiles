{ pkgs, lib, ... }:

{
  home.packages = [ pkgs.starship ];

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = false;
      command_timeout = 1000;
      palette = "dracula";
      format = lib.concatStrings [
        "$directory"
        "$character"
      ];
      right_format = lib.concatStrings [
        "$all"
      ];

      docker_context = {
        disabled = true;
      };

      git_commit = {
        disabled = false;
        only_detached = false;
        tag_disabled = false;
      };

      palettes.dracula = {
        background = "#282a36";
        current_line = "#44475a";
        foreground = "#f8f8f2";
        comment = "#6272a4";
        cyan = "#8be9fd";
        green = "#50fa7b";
        orange = "#ffb86c";
        pink = "#ff79c6";
        purple = "#bd93f9";
        red = "#ff5555";
        yellow = "#f1fa8c";
      };
    };
  };
}
