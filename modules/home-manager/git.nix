{ pkgs, lib, ... }:

let
  beamsCommitMsg = pkgs.writeShellApplication {
    name = "beams-commit-msg";
    runtimeInputs = [ pkgs.gnused pkgs.gawk ];
    text = ''
      # shellcheck disable=SC2016
      sed -e '/^# -* >8 -*$/,$d' -e '/^#/d' "$1" | awk '
      function reject(reason) { print "commit-msg: " reason > "/dev/stderr"; failed = 1 }
      { line[NR] = $0 }
      NR == 1 && /^(Merge|Revert|fixup!|squash!|amend!) / { generated = 1; exit }
      END {
        if (generated) exit
        subject = line[1]
        if (length(subject) > 50) reject("subject exceeds 50 characters (" length(subject) ")")
        if (subject !~ /^[A-Z]/) reject("subject must start with a capital letter")
        if (subject ~ /\.$/) reject("subject must not end with a period")
        if (NR > 1 && line[2] != "") reject("separate subject from body with a blank line")

        last = NR
        while (last > 1 && line[last] == "") last--
        trailers = last + 1
        for (i = last; i > 2 && line[i] ~ /^[[:alnum:]-]+: /; i--) trailers = i
        if (line[trailers - 1] != "") trailers = last + 1

        for (i = 2; i < trailers; i++)
          if (length(line[i]) > 72 && line[i] !~ /:\/\//) reject("line " i " exceeds 72 characters")
        exit failed
      }'
    '';
  };
in
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

      hook.beams = {
        command = lib.getExe beamsCommitMsg;
        event = "commit-msg";
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
