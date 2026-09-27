{ pkgs, config }:

let
  homebrew = import ./brew.nix pkgs;

  storePaths = builtins.listToAttrs (map
    (entry: {
      name = builtins.unsafeDiscardStringContext (builtins.baseNameOf entry.package.outPath);
      value = { commandPrefix = entry.commandPrefix or ""; };
    })
    homebrew.formulae);

  brewfile = pkgs.writeText "Brewfile" (
    pkgs.lib.concatMapStrings (entry: ''brew "${entry.formula}"'' + "\n") homebrew.formulae
    + pkgs.lib.concatMapStrings (cask: ''cask "${cask}"'' + "\n") homebrew.casks
  );
in
pkgs.runCommand "dotfiles-portable"
{
  nativeBuildInputs = [ pkgs.python3 ];
  storePaths = builtins.toJSON storePaths;
  passAsFile = [ "storePaths" ];
}
  ''
    root=dotfiles-portable
    mkdir -p "$root"
    python3 ${./bundle.py} \
      --home-files ${config.home-files} \
      --vim ${pkgs.lib.getExe' config.programs.vim.package "vim"} \
      --store-paths "$storePathsPath" \
      --output "$root/home"
    cp ${brewfile} "$root/Brewfile"
    install -m 755 ${./install.sh} "$root/install.sh"

    mkdir -p "$out"
    tar -czf "$out/portable.tar.gz" "$root"
  ''
