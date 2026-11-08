{ pkgs, ... }:

{
  imports = [
    ../../modules/common
    ../../modules/zsh
    ./system.nix
    ./environment.nix
    ./homebrew.nix
    ./github-runner.nix
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

    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" "vincent" "@admin" ];
    };

    # Builds the Home Manager configurations of the Linux hosts locally
    linux-builder = {
      enable = true;
      ephemeral = true;
      systems = [ "aarch64-linux" ];
      supportedFeatures = [ "benchmark" "big-parallel" "nixos-test" ];
      maxJobs = 4;
      config.virtualisation = {
        cores = 6;
        darwin-builder = {
          memorySize = 12 * 1024;
          diskSize = 60 * 1024;
          min-free = 10 * 1024 * 1024 * 1024;
          max-free = 30 * 1024 * 1024 * 1024;
        };
      };
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
