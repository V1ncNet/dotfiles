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

    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" "vincent" "@admin" ];
    };

    # Builds the Home Manager configurations of the Linux hosts locally
    linux-builder = {
      enable = true;
      ephemeral = true;
      systems = [ "aarch64-linux" "x86_64-linux" ];
      config.boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
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
