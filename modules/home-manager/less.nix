{ pkgs, lib, config, ... }:

let
  # lesspipe dropped mdcat in 2.21, so render Markdown here and highlight the
  # original (file name with a trailing colon) with bat
  lessfilter = pkgs.writeShellScript "lessfilter" ''
    case "$1" in
      *.md|*.MD|*.markdown)
        exec ${lib.getExe' pkgs.mdcat "mdcat"} --ansi -- "$1" ;;
      *.md:|*.MD:|*.markdown:)
        exec ${lib.getExe config.programs.bat.package} --color=always --paging=never --style=plain -- "''${1%:}" ;;
    esac
    exit 1
  '';

  lessOptions = "-R --use-color -Dd+r -Du+b -DP--s";
in
{
  programs.bat = {
    enable = true;

    config = {
      theme = "ansi";
    };
  };

  programs.less.enable = true;
  programs.lesspipe.enable = true;

  home.packages = [ pkgs.mdcat ];

  # lesspipe runs ~/.lessfilter before looking for lessfilter in PATH
  home.file.".lessfilter" = {
    source = lessfilter;
    executable = true;
  };

  home.sessionVariables = {
    LESS = lessOptions;
    LESSQUIET = "1";
    MANROFFOPT = "-c";
    # less reads $MORE instead of $LESS when invoked as more
    MORE = lessOptions;
  };
}
