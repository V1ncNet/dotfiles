{ inputs, nixpkgs, home-manager, ... }:

{
  "vincent@bach" = home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.aarch64-linux;
    extraSpecialArgs = { inherit inputs; };

    modules = [
      {
        home = {
          username = "vincent";
          homeDirectory = "/home/vincent";
          stateVersion = "24.05";
        };
      }
      ./base.nix
    ];
  };

  "vincent@ceres" = home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    extraSpecialArgs = { inherit inputs; };

    modules = [
      {
        home = {
          username = "vincent";
          homeDirectory = "/home/vincent";
          stateVersion = "24.05";
        };
      }
      ./base.nix
    ];
  };

  "vincent@sagittarius" = home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.aarch64-linux;
    extraSpecialArgs = { inherit inputs; };

    modules = [
      {
        home = {
          username = "vincent";
          homeDirectory = "/home/vincent";
          stateVersion = "24.05";
        };
      }
      ./base.nix
    ];
  };
}
