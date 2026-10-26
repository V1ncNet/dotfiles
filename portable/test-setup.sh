#!/usr/bin/env bash
set -euo pipefail

readonly setup_script="$(cd "$(dirname "$0")" && pwd)/setup.sh"
readonly tools=(bash cat dirname env grep mkdir mktemp rm tar uname)
failures=0

new_sandbox() {
  sandbox="$(mktemp -d)"
  mkdir -p "$sandbox/bin" "$sandbox/home" "$sandbox/tmp"
  local tool
  for tool in "${tools[@]}"; do
    ln -s "$(command -v "$tool")" "$sandbox/bin/$tool"
  done
  build_export
}

build_export() {
  local export_root="$sandbox/export/dotfiles-portable"
  mkdir -p "$export_root"
  echo 'brew "fzf"' > "$export_root/Brewfile"
  cat > "$export_root/install.sh" <<'EOF'
#!/usr/bin/env bash
stdin=other
[[ -p /dev/stdin ]] && stdin=pipe
echo "home=$HOME stdin=$stdin" > "$HOME/installed"
EOF
  chmod +x "$export_root/install.sh"
  tar -czf "$sandbox/portable.tar.gz" -C "$sandbox/export" dotfiles-portable
}

stub() {
  local name="$1" body="$2"
  rm -f "$sandbox/bin/$name"
  printf '#!/bin/bash\necho "$*" >> "%s/%s.log"\n%s\n' "$sandbox" "$name" "$body" > "$sandbox/bin/$name"
  chmod +x "$sandbox/bin/$name"
}

stub_brew() {
  stub brew "if [[ -p /dev/stdin ]]; then echo 'stdin=pipe' >> '$sandbox/brew.log'; fi"
}

stub_downloader() {
  stub "$1" "cat '$sandbox/portable.tar.gz'"
}

run_setup() {
  local script="${1:-$setup_script}"
  status=0
  cat "$script" | env -i \
    HOME="$sandbox/home" \
    PATH="$sandbox/bin" \
    TMPDIR="$sandbox/tmp" \
    HOMEBREW_PREFIX="$sandbox/homebrew" \
    DOTFILES_PORTABLE_URL="https://example.invalid/portable.tar.gz" \
    bash > "$sandbox/stdout" 2> "$sandbox/stderr" || status=$?
}

fail() {
  echo "  $1" >&2
  exit 1
}

assert_status() {
  [[ "$status" == "$1" ]] || fail "expected exit status $1, got $status: $(cat "$sandbox/stderr")"
}

assert_file_contains() {
  grep -qF -- "$2" "$1" 2> /dev/null || fail "expected $1 to contain '$2'"
}

assert_file_lacks() {
  ! grep -qF -- "$2" "$1" 2> /dev/null || fail "expected $1 not to contain '$2'"
}

assert_missing() {
  [[ ! -e "$1" ]] || fail "expected $1 not to exist"
}

assert_empty_directory() {
  [[ -z "$(ls -A "$1")" ]] || fail "expected $1 to be empty"
}

test_installs_export_from_piped_script() {
  stub_brew
  stub_downloader curl
  run_setup
  assert_status 0
  assert_file_contains "$sandbox/curl.log" "https://example.invalid/portable.tar.gz"
  assert_file_contains "$sandbox/brew.log" "bundle --file"
  assert_file_contains "$sandbox/brew.log" "dotfiles-portable/Brewfile"
  assert_file_contains "$sandbox/home/installed" "home=$sandbox/home stdin=other"
  assert_file_lacks "$sandbox/brew.log" "stdin=pipe"
  assert_empty_directory "$sandbox/tmp"
}

test_downloads_with_wget_without_curl() {
  stub_brew
  stub_downloader wget
  run_setup
  assert_status 0
  assert_file_contains "$sandbox/wget.log" "https://example.invalid/portable.tar.gz"
  assert_file_contains "$sandbox/home/installed" "home=$sandbox/home"
}

test_loads_homebrew_outside_path() {
  mkdir -p "$sandbox/homebrew/bin"
  stub brew "if [[ \$1 == shellenv ]]; then echo 'export PATH=\"$sandbox/homebrew/bin:\$PATH\"'; fi"
  mv "$sandbox/bin/brew" "$sandbox/homebrew/bin/brew"
  stub_downloader curl
  run_setup
  assert_status 0
  assert_file_contains "$sandbox/brew.log" "shellenv"
  assert_file_contains "$sandbox/brew.log" "bundle --file"
}

test_fails_without_homebrew() {
  stub_downloader curl
  run_setup
  assert_status 1
  assert_file_contains "$sandbox/stderr" "https://brew.sh"
  assert_missing "$sandbox/curl.log"
  assert_missing "$sandbox/home/installed"
}

test_fails_on_linux() {
  stub uname 'echo Linux'
  stub_brew
  stub_downloader curl
  run_setup
  assert_status 1
  assert_file_contains "$sandbox/stderr" "macOS"
  assert_missing "$sandbox/curl.log"
  assert_missing "$sandbox/home/installed"
}

test_truncated_script_does_nothing() {
  stub_brew
  stub_downloader curl
  sed '$d' "$setup_script" > "$sandbox/truncated.sh"
  run_setup "$sandbox/truncated.sh"
  assert_missing "$sandbox/curl.log"
  assert_missing "$sandbox/brew.log"
  assert_missing "$sandbox/home/installed"
}

test_fails_when_download_fails() {
  stub_brew
  stub curl 'exit 22'
  run_setup
  assert_status 1
  assert_file_contains "$sandbox/stderr" "https://example.invalid/portable.tar.gz"
  assert_missing "$sandbox/home/installed"
  assert_empty_directory "$sandbox/tmp"
}

test_reports_failed_wget_download() {
  stub_brew
  stub wget 'exit 8'
  run_setup
  assert_status 1
  assert_file_contains "$sandbox/stderr" "https://example.invalid/portable.tar.gz"
  assert_missing "$sandbox/home/installed"
  assert_empty_directory "$sandbox/tmp"
}

test_fails_without_downloader() {
  stub_brew
  run_setup
  assert_status 1
  assert_file_contains "$sandbox/stderr" "curl or wget"
  assert_missing "$sandbox/home/installed"
}

run_test() {
  set +e
  (
    set -e
    "$1"
  )
  local result=$?
  set -e
  if ((result != 0)); then
    echo "  FAILED with exit status $result" >&2
    failures=$((failures + 1))
  fi
}

for test in $(declare -F | awk '{ print $3 }' | grep '^test_'); do
  echo "$test"
  new_sandbox
  run_test "$test"
  rm -rf "$sandbox"
done

if ((failures > 0)); then
  echo "$failures test(s) failed" >&2
  exit 1
fi
