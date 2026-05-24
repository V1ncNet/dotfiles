{ pkgs, ... }:

{
  home.packages = [ pkgs.git ];

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Vincent Nadoll";
        email = "vincent.nadoll@googlemail.com";
      };

      aliases = {
        resotre = "restore";
      };

      extraConfig = {
        commit = {
          verbose = true;
        };

        pull = {
          rebase = true;
        };

        rebase = {
          autoStash = true;
          rebaseMerges = "no-rebase-cousins";
        };

        init = {
          defaultBranch = "main";
        };

        push = {
          autoSetupRemote = true;
        };

        column = {
          ui = "auto";
        };

        branch = {
          sort = "-committerdate";
        };

        rerere = {
          enabled = true;
        };
      };
    };

    ignores = [
      ".DS_Store"
      ".env"
      ".env.keys"
      ".envrc"
      "~$*"
      ".cfg"
      ".venv/"
    ];
  };
}
