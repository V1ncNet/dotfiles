#!/bin/bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
failures=0

run_case() {
  local name=$1 power=$2 busy_polls=$3 loaded=$4 expected=$5
  local dir
  dir=$(mktemp -d)
  mkdir "$dir/bin"
  echo "$power" > "$dir/power"
  echo "$busy_polls" > "$dir/busy"
  : > "$dir/calls"

  cat > "$dir/bin/pmset" <<EOF
#!/bin/bash
cat "$dir/power"
EOF
  cat > "$dir/bin/pgrep" <<EOF
#!/bin/bash
busy=\$(cat "$dir/busy")
[ "\$busy" -gt 0 ] || exit 1
echo \$((busy - 1)) > "$dir/busy"
EOF
  cat > "$dir/bin/launchctl" <<EOF
#!/bin/bash
echo "\$*" >> "$dir/calls"
[ "\$1" != print ] || [ "$loaded" = yes ]
EOF
  cat > "$dir/bin/sleep" <<EOF
#!/bin/bash
[ "$power" != battery-then-ac ] || echo "Now drawing from 'AC Power'" > "$dir/power"
EOF
  chmod +x "$dir"/bin/*

  case $power in
    ac) echo "Now drawing from 'AC Power'" > "$dir/power" ;;
    battery | battery-then-ac) echo "Now drawing from 'Battery Power'" > "$dir/power" ;;
  esac

  PATH="$dir/bin:/usr/bin:/bin" RUNNER_LABEL=test.runner "$here/github-runner-power.sh"

  local actual
  actual=$(paste -sd';' "$dir/calls")
  if [ "$actual" != "$expected" ]; then
    echo "FAIL $name: expected '$expected', got '$actual'" >&2
    failures=$((failures + 1))
  fi
  rm -rf "$dir"
}

service=system/test.runner
plist=/Library/LaunchDaemons/test.runner.plist

run_case "AC, runner not loaded" ac 0 no \
  "enable $service;print $service;bootstrap system $plist"
run_case "AC, runner loaded" ac 0 yes \
  "enable $service;print $service"
run_case "battery, idle" battery 0 yes \
  "disable $service;bootout $service"
run_case "battery, job finishes first" battery 2 yes \
  "disable $service;bootout $service"
run_case "cable plugged in while a job runs" battery-then-ac 5 yes \
  "disable $service;enable $service;print $service"

[ "$failures" -eq 0 ] && echo OK
exit "$failures"
