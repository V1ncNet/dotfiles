{ pkgs, inputs, ... }:

let
  worktreeInit = inputs.git-worktree-init.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  programs.git.settings = {
    alias.wt = "!${worktreeInit}/bin/git-wt";

    hook.worktree-init = {
      command = "${worktreeInit}/hook.sh";
      event = "post-checkout";
    };
  };
}
