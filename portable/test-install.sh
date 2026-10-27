#!/usr/bin/env bash
set -euo pipefail

readonly install_script="$(cd "$(dirname "$0")" && pwd)/install.sh"
readonly test_lib="$(cd "$(dirname "$0")" && pwd)/test-lib.sh"

source "$test_lib"

new_sandbox() {
  sandbox="$(mktemp -d)"
  mkdir -p "$sandbox/bin" "$sandbox/home"
  build_export
  stub brew ""
  stub id "echo 501"
  stub launchctl ""
  stub sleep ""
}

build_export() {
  export_root="$sandbox/export/dotfiles-portable"
  mkdir -p "$export_root/home/Library/LaunchAgents"
  touch "$export_root/Brewfile"
  cp "$install_script" "$export_root/install.sh"
  echo "/__HOME__/x" > "$export_root/home/Library/LaunchAgents/test.agent.plist"
}

run_install() {
  status=0
  env -i \
    HOME="$sandbox/home" \
    PATH="$sandbox/bin:/usr/bin:/bin" \
    bash "$export_root/install.sh" > "$sandbox/stdout" 2> "$sandbox/stderr" || status=$?
}

test_installs_and_loads_launch_agent() {
  run_install
  assert_status 0
  local agent="$sandbox/home/Library/LaunchAgents/test.agent.plist"
  [[ -f "$agent" && ! -L "$agent" ]] || fail "expected $agent to be a regular file"
  assert_file_contains "$agent" "$sandbox/home/x"
  assert_file_contains "$sandbox/launchctl.log" "bootstrap gui/501 $agent"
}

test_reinstall_reloads_launch_agent() {
  run_install
  assert_status 0
  run_install
  assert_status 0
  local agent="$sandbox/home/Library/LaunchAgents/test.agent.plist"
  local expected
  expected="$(printf 'bootout gui/501/test.agent\nbootstrap gui/501 %s\n' "$agent")"
  [[ "$(cat "$sandbox/launchctl.log")" == "$expected"$'\n'"$expected" ]] \
    || fail "unexpected launchctl calls: $(cat "$sandbox/launchctl.log")"
}

test_failed_bootstrap_only_warns() {
  stub launchctl '[[ $1 == bootstrap ]] && exit 5 || exit 0'
  run_install
  assert_status 0
  assert_file_contains "$sandbox/stderr" "test.agent"
}

test_explains_location_permission_for_appearance_agent() {
  touch "$export_root/home/Library/LaunchAgents/org.nix-community.home.appearance.plist"
  run_install
  assert_status 0
  assert_file_contains "$sandbox/stdout" "CoreLocationCLI"
  assert_file_contains "$sandbox/stdout" "Location Services"
}

test_omits_location_hint_without_appearance_agent() {
  run_install
  assert_status 0
  assert_file_lacks "$sandbox/stdout" "Location Services"
}

run_all_tests
