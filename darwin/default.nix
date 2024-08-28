{ inputs, nixpkgs, nix-darwin, home-manager, ...}:

{
  Iris = nix-darwin.lib.darwinSystem {
    modules = [
      ./Iris
      home-manager.darwinModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        home-manager.users.vincent.home = {
          username = "vincent";
          homeDirectory = "/Users/vincent";
          stateVersion = "24.05";
        };
      }
    ];
  };
}
