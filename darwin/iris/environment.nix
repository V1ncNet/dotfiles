{ pkgs, ... }:

{
  environment = {
    variables = {
      EDITOR = "vim";
      VISUAL = "vim";
    };

    systemPackages = with pkgs; [
      ffmpeg-full
      graphviz
      hcloud
      imagemagick
      jq
      mas
      maven
      ollama
      pandoc
      plantuml
      python312
      taskwarrior3
      vim
      wget
      yq
    ];

    darwinConfig = "$HOME/Code/vinado/dotfiles/darwin/iris/default.nix";
  };

  fonts.packages = with pkgs; [
    cardo
    crimson-pro
    montserrat
    roboto
    nerd-fonts.hack
  ];
}
