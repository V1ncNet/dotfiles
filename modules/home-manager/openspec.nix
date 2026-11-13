{ pkgs, ... }:

let
  openspec = pkgs.openspec.overrideAttrs (final: _: {
    version = "2.0.0";

    src = pkgs.fetchFromGitHub {
      owner = "Fission-AI";
      repo = "OpenSpec";
      tag = "v${final.version}";
      hash = "sha256-NF7vPKcIgE1eCzcLcjHEGJvdMoueABgg6miudBWxs7w=";
    };

    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit (final) pname version src;
      pnpm = pkgs.pnpm_10;
      fetcherVersion = 3;
      hash = "sha256-+Hqb9DnxsCZkAjb3fOfYJiPpfoX+m4MDKlF02Uxs2bw=";
    };

    postFixup = ''
      wrapProgram $out/bin/openspec --set-default OPENSPEC_TELEMETRY 0
    '';
  });
in
{
  home.packages = [ openspec ];
}
