{
  imports = [
    ../../modules/claude-code-defaults.nix
    ../../modules/unslop-skill.nix
  ];

  claudeCode.defaults.theme = "auto";
}
