{ inputs, nixpkgs, nix-darwin, home-manager, mac-app-util, ...}:

{
  iris = nix-darwin.lib.darwinSystem {
    modules = [
      mac-app-util.darwinModules.default
      ./iris
      home-manager.darwinModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.vincent = import ./iris/home.nix;
        home-manager.sharedModules = [
          mac-app-util.homeManagerModules.default
        ];
      }
    ];
  };
}
