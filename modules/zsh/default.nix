{ pkgs, vars,... }:

{
  users.users.${vars.username} = {
    shell = pkgs.zsh;
  };

  environment = {
    loginShell = pkgs.zsh;

    shells = with pkgs; [
      zsh
    ];
  };

  programs.zsh = {
    enable = true;
    enableSyntaxHighlighting = true;
  };
}
