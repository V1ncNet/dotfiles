{ pkgs, ... }:

{
  environment = {
    variables = {
      EDITOR = "vim";
      VISUAL = "vim";
    };

    systemPackages = with pkgs; [
      ansible
      ansible-lint
      ffmpeg-full
      graphviz
      hcloud
      imagemagick
      jq
      maven
      pandoc
      plantuml
      stats
      yq
    ];

    darwinConfig = "$HOME/src/vinado/dotfiles/darwin/Iris/default.nix";
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
