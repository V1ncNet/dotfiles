{
  description = "Vinado's system flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, mac-app-util }:
  {
    darwinConfigurations = (
      import ./darwin {
        inherit (nixpkgs) lib;
        inherit inputs nixpkgs nix-darwin home-manager mac-app-util;
      }
    );

    homeConfigurations = (
      import ./nix {
        inherit (nixpkgs) lib;
        inherit inputs nixpkgs home-manager;
      }
    );

    apps.aarch64-darwin = import ./apps {
      inherit self;
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
    };
  };
}
