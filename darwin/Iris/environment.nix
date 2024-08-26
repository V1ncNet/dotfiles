{ pkgs, ... }:

{
  environment = {
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
