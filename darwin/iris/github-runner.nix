{ config, pkgs, ... }:

let
  name = "ops-flake";
  repository = "V1ncNet/ops";
  expectedWorkflowRef = "${repository}/.github/workflows/flake.yml@refs/heads/main";
  piCache = "https://nixos-raspberrypi.cachix.org";

  rejectForeignJobs = pkgs.writeShellScript "${name}-job-started.sh" ''
    reject() { echo "Runner ${name} only takes the flake workflow of ${repository}, refusing: $1" >&2; exit 1; }
    [ "$GITHUB_EVENT_NAME" = pull_request_target ] || reject "event $GITHUB_EVENT_NAME"
    [ "$GITHUB_REPOSITORY" = ${repository} ] || reject "repository $GITHUB_REPOSITORY"
    [ "$GITHUB_WORKFLOW_REF" = ${expectedWorkflowRef} ] || reject "workflow $GITHUB_WORKFLOW_REF"
  '';
in
{
  services.github-runners.${name} = {
    enable = true;
    inherit name;
    url = "https://github.com/${repository}";
    tokenFile = "${config.launchd.daemons."github-runner-${name}".environment.RUNNER_ROOT}.token";
    extraLabels = [ "iris" ];
    replace = true;
    user = null;
    group = null;
    extraPackages = [ pkgs.gh ];
    extraEnvironment.ACTIONS_RUNNER_HOOK_JOB_STARTED = "${rejectForeignJobs}";
  };

  nix.settings = {
    trusted-substituters = [ piCache ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };
}
