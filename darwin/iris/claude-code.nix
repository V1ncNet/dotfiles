{ pkgs, lib, config, ... }:

let
  settings = "${config.home.homeDirectory}/.claude/settings.json";

  # Claude Code has no layer below the user settings, so these defaults are
  # merged into the writable settings file, where local changes take precedence
  defaults = (pkgs.formats.json { }).generate "claude-code-defaults.json" {
    theme = "auto";
  };
in
{
  home.activation.claudeCodeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [[ -L "${settings}" || ! -e "${settings}" ]]; then
      run rm -f "${settings}"
      run mkdir -p "$(dirname "${settings}")"
      run install -m 644 ${defaults} "${settings}"
    else
      tmp=$(mktemp "${settings}.XXXXXX")
      if ${lib.getExe pkgs.jq} -s '.[0] * .[1]' ${defaults} "${settings}" > "$tmp"; then
        chmod 644 "$tmp"
        run mv "$tmp" "${settings}"
        if [[ -v DRY_RUN ]]; then rm -f "$tmp"; fi
      else
        rm -f "$tmp"
        warnEcho "Could not merge Claude Code defaults into ${settings}"
      fi
    fi
  '';
}
