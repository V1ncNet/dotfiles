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
      dotenvx
      ffmpeg-full
      gh
      graphviz
      hcloud
      imagemagick
      jq
      mas
      maven
      ollama
      pandoc
      pdftk
      pgloader
      plantuml
      postgresql
      python3
      taskwarrior3
      uv
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
