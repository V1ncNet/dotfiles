{ inputs, nixpkgs, nix-darwin, home-manager, ...}:

let
  systemconfig = system: {
    system = system;
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  };
in {
  Iris = let
    inherit (systemconfig "aarch64-darwin") system pkgs;

    vars = {
      username = "vincent";
    };
  in nix-darwin.lib.darwinSystem {
    inherit system;
    specialArgs = { inherit inputs system pkgs vars; };

    modules = [
      ./Iris
      home-manager.darwinModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        home-manager.users.${vars.username}.home = {
          username = "${vars.username}";
          homeDirectory = "/Users/${vars.username}";
          stateVersion = "24.05";
        };
      }
    ];
  };
}
