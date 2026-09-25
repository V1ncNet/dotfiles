{ pkgs, lib, ... }:

{
  home.packages = [ pkgs.starship ];

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = false;
      command_timeout = 1000;
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$character"
      ];
      right_format = lib.concatStrings [
        "$all"
      ];

      username = {
        format = "[$user]($style)@";
      };

      hostname = {
        format = "[$hostname]($style):";
      };

      directory = {
        truncate_to_repo = false;
        truncation_symbol = "…/";
        truncation_length = 5;
        before_repo_root_style = "cyan dimmed";
        repo_root_style = "bold cyan";
      };

      docker_context = {
        disabled = true;
      };

      git_branch = {
        format = "[$symbol$branch(:$remote_branch)]($style) ";
      };
    };
  };
}
