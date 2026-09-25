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
    gnupg.agent = {
      enable = true;
    };
  };
}
