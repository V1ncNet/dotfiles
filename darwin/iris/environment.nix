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

    etc."hosts" = {
      enable = true;

      text = ''
        127.0.0.1       localhost host.docker.internal
        255.255.255.255 broadcasthost
        ::1             localhost
      '';
    };
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
