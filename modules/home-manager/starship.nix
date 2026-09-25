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
        "$git_branch"
        "$git_status"
        "$java"
        "$nodejs"
        "$python"
        "\${env_var.VIRTUAL_ENV}"
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

      git_branch = {
        format = "[$symbol$branch(:$remote_branch)]($style) ";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
      };

      # Project type only, without versions
      java = {
        format = "[$symbol]($style) ";
        symbol = "";
      };

      nodejs = {
        format = "[$symbol]($style) ";
        symbol = "";
      };

      python = {
        format = "[$symbol]($style) ";
        symbol = "";
      };

      env_var.VIRTUAL_ENV = {
        format = "[venv]($style) ";
        style = "yellow";
      };
    };
  };
}
