{ inputs, ... }:

{
  home.file.".claude/skills/unslop".source = builtins.path {
    name = "unslop";
    path = "${inputs.cursor-plugins}/harness/pstack/claude-code/skills/unslop";
  };
}
