{
  programs.claude-code = {
    enable = true;

    # Installed with the native installer, which keeps itself up to date
    package = null;

    settings = {
      theme = "auto";
    };
  };
}
