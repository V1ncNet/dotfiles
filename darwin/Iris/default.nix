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

  services = {
    nix-daemon.enable = true;
  };

  nix = {
    package = pkgs.nix;
    configureBuildUsers = true;
    useDaemon = true;

    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" "vincent" "@admin" ];
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      interval.Day = 7;
      options = "--delete-older-than 7d";
    };
  };

  system.stateVersion = 4;
}
