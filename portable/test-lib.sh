failures=0

stub() {
  local name="$1" body="$2"
  rm -f "$sandbox/bin/$name"
  printf '#!/bin/bash\necho "$*" >> "%s/%s.log"\n%s\n' "$sandbox" "$name" "$body" > "$sandbox/bin/$name"
  chmod +x "$sandbox/bin/$name"
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

assert_line_count() {
  local count
  count=$(($(wc -l < "$1")))
  ((count == $2)) || fail "expected $2 line(s) in $1, got $count: $(cat "$1")"
}

assert_missing() {
  [[ ! -e "$1" ]] || fail "expected $1 not to exist"
}

assert_empty_directory() {
  [[ -z "$(ls -A "$1")" ]] || fail "expected $1 to be empty"
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

run_all_tests() {
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
}
