#!/bin/bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
failures=0

run_case() {
  local name=$1 power=$2 workers=$3 loaded=$4 expected=$5
  local dir
  dir=$(mktemp -d)
  mkdir "$dir/bin"
  echo "$workers" > "$dir/workers"
  : > "$dir/calls"

  case $power in
    ac) echo "Now drawing from 'AC Power'" > "$dir/power" ;;
    battery | battery-then-ac) echo "Now drawing from 'Battery Power'" > "$dir/power" ;;
  esac

  cat > "$dir/bin/pmset" <<EOF
#!/bin/bash
cat "$dir/power"
EOF
  cat > "$dir/bin/pgrep" <<EOF
#!/bin/bash
read -r next rest < "$dir/workers" || next=n
echo "\$rest" > "$dir/workers"
[ "\$next" = y ]
EOF
  cat > "$dir/bin/pkill" <<EOF
#!/bin/bash
echo "pkill \$*" >> "$dir/calls"
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

  PATH="$dir/bin:/usr/bin:/bin" RUNNER_LABEL=test.runner "$here/github-runner-power.sh"

  local actual
  actual=$(paste -sd';' "$dir/calls")
  if [ "$actual" != "$expected" ]; then
    echo "FAIL $name" >&2
    echo "  expected: $expected" >&2
    echo "  actual:   $actual" >&2
    failures=$((failures + 1))
  fi
  rm -rf "$dir"
}

service=system/test.runner
plist=/Library/LaunchDaemons/test.runner.plist
freeze="pkill -STOP Runner.Listener"
thaw="pkill -CONT Runner.Listener"

run_case "AC, runner not loaded" ac "" no \
  "$thaw;enable $service;print $service;bootstrap system $plist"
run_case "AC, runner loaded" ac "" yes \
  "$thaw;enable $service;print $service"
run_case "battery, idle" battery "" yes \
  "disable $service;$freeze;bootout $service;$thaw"
run_case "battery, job finishes first" battery "y y" yes \
  "disable $service;$freeze;bootout $service;$thaw"
run_case "battery, job slips in before the freeze" battery "n y n" yes \
  "disable $service;$freeze;$thaw;$freeze;bootout $service;$thaw"
run_case "cable plugged in while a job runs" battery-then-ac "y y y y" yes \
  "disable $service;$thaw;enable $service;print $service"

[ "$failures" -eq 0 ] && echo OK
exit "$failures"
