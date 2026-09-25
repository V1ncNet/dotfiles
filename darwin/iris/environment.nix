{ pkgs, ... }:

{
  environment = {
    variables = {
      EDITOR = "vim";
      VISUAL = "vim";
    };

    systemPackages = with pkgs; [
      asciidoctor-with-extensions
      ditaa
      ffmpeg-full
      graphviz
      hcloud
      imagemagick
      jq
      mas
      maven
      obsidian
      ollama
      pandoc
      plantuml
      python3
      taskwarrior3
      vim
      wget
      yq
    ];
  };

  fonts.packages = with pkgs; [
    cardo
    crimson-pro
    montserrat
    roboto
    nerd-fonts.hack
  ];
}
