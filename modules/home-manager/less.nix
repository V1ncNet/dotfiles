{ pkgs, lib, config, ... }:

let
  # lesspipe renders Markdown with mdcat, but shows the original (file name
  # with a trailing colon) without colors, so highlight it with bat instead
  lessfilter = pkgs.writeShellScriptBin "lessfilter" ''
    case "$1" in
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

  home.packages = [ lessfilter pkgs.mdcat ];

  home.sessionVariables = {
    LESS = lessOptions;
    LESSQUIET = "1";
    MANROFFOPT = "-c";
    # less reads $MORE instead of $LESS when invoked as more
    MORE = lessOptions;
  };
}
