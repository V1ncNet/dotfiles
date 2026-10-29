{ pkgs, lib, config, ... }:

let
  claude = import ../../themes/claude.nix;

  t3 = "${config.home.homeDirectory}/.t3/bin/t3";
  themeFile = "${config.home.homeDirectory}/.t3/userdata/themes/claude.json";

  slot = index: theme: builtins.elemAt theme.palette index;
  field = name: theme: theme.${name};

  canvas = field "background";
  text = field "foreground";
  accent = field "cursor";
  subtle = field "selectionBackground";
  muted = slot 8;

  colorMap = {
    canvas = canvas;
    chrome = canvas;
    toolbar = canvas;
    toolbarForeground = text;
    toolbarBorder = subtle;
    toolbarControl = subtle;
    toolbarControlForeground = text;
    toolbarControlHover = subtle;
    surface = canvas;
    surfaceRaised = subtle;
    surfaceOverlay = subtle;
    text = text;
    textMuted = muted;
    border = subtle;
    input = subtle;
    focus = accent;
    accent = accent;
    secondary = subtle;
    secondaryForeground = text;
    muted = subtle;
    mutedForeground = muted;
    placeholder = muted;
    secondaryLabel = muted;
    iconMuted = muted;
    error = slot 1;
    errorSurface = subtle;
    warning = slot 3;
    warningSurface = subtle;
    update = slot 4;
    updateSurface = subtle;
    accentSurface = subtle;
    accentSurfaceForeground = text;
    messageSurface = subtle;
    messageForeground = text;
    messageAction = subtle;
    messageActionForeground = text;
    messageActionHover = subtle;
    codeBackground = subtle;
    codeForeground = text;
    searchMatchBackground = slot 3;
    searchMatchForeground = canvas;
    searchMatchActiveBackground = accent;
    sidebar = canvas;
    sidebarForeground = text;
    sidebarMutedForeground = muted;
    sidebarControlSurface = subtle;
    sidebarRowHover = subtle;
    sidebarRowActive = subtle;
    sidebarRowSelected = subtle;
    sidebarBorder = subtle;
    terminalBackground = canvas;
    terminalForeground = text;
    terminalCursor = accent;
    terminalSelection = subtle;
    terminalScrollbar = muted;
    terminalScrollbarHover = text;
  };

  # Text on the accent color needs the dark ink of the theme: the foreground
  # in light mode, the background in dark mode
  onAccent = {
    light = text;
    dark = canvas;
  };

  # Status text sits on a subtle surface, where the status colors of the
  # dark palette are too dim, so it uses the bright slots instead
  statusForeground = {
    light = { error = slot 1; warning = slot 3; update = slot 4; };
    dark = { error = slot 9; warning = slot 11; update = slot 12; };
  };

  colorsOf = variant:
    lib.mapAttrs (_: pick: pick claude.${variant}) (colorMap // {
      accentForeground = onAccent.${variant};
      searchMatchActiveForeground = onAccent.${variant};
      errorForeground = statusForeground.${variant}.error;
      warningForeground = statusForeground.${variant}.warning;
      updateForeground = statusForeground.${variant}.update;
    });

  theme = {
    version = 1;
    name = "Claude";
    appearance = "light";
    colors = colorsOf "light";
    variants.dark = colorsOf "dark";
  };

  themeJson = (pkgs.formats.json { }).generate "claude-t3-code-theme.json" theme;
  paletteJson = (pkgs.formats.json { }).generate "claude-palette.json" claude;

  checkedThemeJson = pkgs.runCommand "claude-t3-code-theme-checked.json" { } ''
    ${lib.getExe pkgs.python3} -I ${./t3-code-theme-check.py} ${themeJson} ${paletteJson}
    cp ${themeJson} $out
  '';
in
{
  # Every `theme set` makes clients reapply the default theme, so the theme
  # is only published when it differs from the published copy
  home.activation.t3CodeTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [[ ! -x "${t3}" ]]; then
      verboseEcho "T3 Code is not installed, skipping its theme"
    elif ! cmp -s ${checkedThemeJson} "${themeFile}"; then
      run ${t3} theme set ${checkedThemeJson} --id claude
    fi
  '';
}
