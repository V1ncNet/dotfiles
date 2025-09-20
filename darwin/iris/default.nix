{ pkgs, ... }:

{
  imports = [
    ../../modules/common
    ../../modules/zsh
    ./system.nix
    ./environment.nix
    ./homebrew.nix
  ];

  users.users.vincent = {
    home = "/Users/vincent";
    shell = pkgs.zsh;
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config = {
    allowUnfree = true;
  };

  nix = {
    enable = true;
    package = pkgs.nix;

    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" "vincent" "@admin" ];
    };

    optimise = {
      automatic = true;
    };

    gc = {
      automatic = true;
      interval.Day = 7;
      options = "--delete-older-than 7d";
    };
  };

  system.stateVersion = 6;
}
