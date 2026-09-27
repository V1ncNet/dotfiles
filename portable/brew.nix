pkgs:

[
  { package = pkgs.bat; formula = "bat"; }
  { package = pkgs.coreutils; formula = "coreutils"; commandPrefix = "g"; }
  { package = pkgs.direnv; formula = "direnv"; }
  { package = pkgs.fzf; formula = "fzf"; }
  { package = pkgs.gawk; formula = "gawk"; }
  { package = pkgs.git; formula = "git"; }
  { package = pkgs.gnused; formula = "gnu-sed"; commandPrefix = "g"; }
  { package = pkgs.lesspipe; formula = "lesspipe"; }
  { package = pkgs.mdcat; formula = "mdcat"; }
  { package = pkgs.starship; formula = "starship"; }
  { package = pkgs.vim; formula = "vim"; }
  { package = pkgs.zoxide; formula = "zoxide"; }
]
