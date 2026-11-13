{ lib, inputs, ... }:

let
  skill = "${inputs.cursor-plugins}/harness/pstack/claude-code/skills/unslop";
  upstream = builtins.readFile "${skill}/SKILL.md";
  invocationLock = "disable-model-invocation: true\n";
  isSingleFile = builtins.attrNames (builtins.readDir skill) == [ "SKILL.md" ];
in
{
  home.file.".claude/skills/unslop/SKILL.md".text =
    lib.throwIfNot isSingleFile "unslop: upstream skill has more files than SKILL.md, link them too"
      (lib.throwIfNot (lib.hasInfix invocationLock upstream)
        "unslop: upstream SKILL.md no longer contains '${lib.removeSuffix "\n" invocationLock}', review the skill"
        (builtins.replaceStrings [ invocationLock ] [ "" ] upstream));
}
