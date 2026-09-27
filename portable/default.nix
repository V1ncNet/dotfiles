{ nixpkgs, home-manager }:

let
  pkgs = nixpkgs.legacyPackages.aarch64-darwin;

  home = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = (import ../modules/home-manager) ++ [ ./module.nix ];
  };
in
import ./bundle.nix { inherit pkgs; inherit (home) config; }
