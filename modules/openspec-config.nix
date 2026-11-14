{ pkgs, lib, config, ... }:

let
  configFile = "${config.xdg.configHome}/openspec/config.json";

  settings = (pkgs.formats.json { }).generate "openspec-config.json" {
    profile = "custom";
    inherit (config.openspec) workflows;
  };
in
{
  options.openspec.workflows = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ "propose" "explore" "apply" "update" "sync" "archive" "verify" ];
    description = "Workflows set in ~/.config/openspec/config.json on every switch, together with the profile `custom`.";
  };

  config.home.activation.openspecConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [[ -L "${configFile}" || ! -e "${configFile}" ]]; then
      run rm -f "${configFile}"
      run mkdir -p "$(dirname "${configFile}")"
      run install -m 644 ${settings} "${configFile}"
    else
      tmp=$(mktemp "${configFile}.XXXXXX")
      if ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "${configFile}" ${settings} > "$tmp"; then
        chmod 644 "$tmp"
        run mv "$tmp" "${configFile}"
        if [[ -v DRY_RUN ]]; then rm -f "$tmp"; fi
      else
        rm -f "$tmp"
        warnEcho "Could not merge OpenSpec settings into ${configFile}"
      fi
    fi
  '';
}
