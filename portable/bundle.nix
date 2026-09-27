{ pkgs, config }:

let
  formulae = import ./brew.nix pkgs;

  storePaths = builtins.listToAttrs (map
    (entry: {
      name = builtins.unsafeDiscardStringContext (builtins.baseNameOf entry.package.outPath);
      value = { commandPrefix = entry.commandPrefix or ""; };
    })
    formulae);

  brewfile = pkgs.writeText "Brewfile"
    (pkgs.lib.concatMapStrings (entry: ''brew "${entry.formula}"'' + "\n") formulae);
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
