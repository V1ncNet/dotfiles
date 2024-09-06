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
      pandoc
      plantuml
      python312
      yq
    ];

    darwinConfig = "$HOME/src/vinado/dotfiles/darwin/iris/default.nix";
  };

  fonts.packages = with pkgs; [
    cardo
    crimson-pro
    montserrat
    (nerdfonts.override {
      fonts = [
        "Hack"
      ];
    })
  ];
}
