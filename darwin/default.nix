{ inputs, nixpkgs, nix-darwin, home-manager, mac-app-util, ...}:

{
  Iris = nix-darwin.lib.darwinSystem {
    modules = [
      mac-app-util.darwinModules.default
      ./Iris
      home-manager.darwinModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.vincent = import ./Iris/home.nix;
        home-manager.sharedModules = [
          mac-app-util.homeManagerModules.default
        ];
      }
    ];
  };
}
