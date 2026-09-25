{ self, pkgs }:

let
  # Non-interactive SSH sessions on the hosts don't have Nix in their PATH
  nixProfile = "/nix/var/nix/profiles/default";

  mkApp = name: text: {
    type = "app";
    program = pkgs.lib.getExe (pkgs.writeShellApplication { inherit name text; });
  };
in
{
  # Build a host's Home Manager configuration locally, copy it and activate it
  deploy = mkApp "deploy" ''
    host="''${1:?usage: nix run .#deploy -- <host>}"

    out=$(nix build --no-link --print-out-paths \
      "${self}#homeConfigurations.\"vincent@$host\".activationPackage")

    # Locally built paths are unsigned, the hosts trust vincent instead
    nix copy --substitute-on-destination --no-check-sigs \
      --to "ssh-ng://$host?remote-program=${nixProfile}/bin/nix-daemon" "$out"

    # The store path is expanded locally on purpose
    # shellcheck disable=SC2029
    ssh "$host" ". ${nixProfile}/etc/profile.d/nix-daemon.sh && $out/activate"
  '';

  # Delete old generations and unreferenced store paths on a host
  gc = mkApp "gc" ''
    host="''${1:?usage: nix run .#gc -- <host>}"

    # shellcheck disable=SC2016
    ssh "$host" '
      df -h /nix
      ${nixProfile}/bin/nix-collect-garbage -d
      df -h /nix
    '
  '';
}
