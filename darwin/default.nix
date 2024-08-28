{ inputs, nixpkgs, nix-darwin, home-manager, ...}:

{
  Iris = nix-darwin.lib.darwinSystem {
    modules = [
      ./Iris
      home-manager.darwinModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.vincent = import ./Iris/home.nix;
      }
    ];
  };
}
