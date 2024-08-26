{ pkgs, system, vars,... }:

{
  imports = [
    ../../modules/zsh
  ];

  users.users.${vars.username} = {
    home = "/Users/${vars.username}";
  };

  nixpkgs.hostPlatform = system;

  services = {
    nix-daemon.enable = true;
  };

  nix = {
    package = pkgs.nix;
    configureBuildUsers = true;
    useDaemon = true;

    settings = {
      experimental-features = "nix-command flakes";
    };

    gc = {
      automatic = true;
      interval.Day = 7;
      options = "--delete-older-than 7d";
    };
  };

  system.stateVersion = 4;
}
