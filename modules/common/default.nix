{ pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      curl
      direnv
      git
      gnupg
      htop
      vim
    ];
  };

  programs = {
    direnv = {
      enable = true;
      silent = true;
    };

    gnupg.agent = {
      enable = true;
    };
  };
}
