#!/bin/bash
set -u

service="system/${RUNNER_LABEL:?}"
plist="/Library/LaunchDaemons/${RUNNER_LABEL}.plist"

on_battery() { pmset -g batt | grep -q "Battery Power"; }
job_running() { pgrep -q Runner.Worker; }
freeze_listener() { pkill -STOP Runner.Listener; }
thaw_listener() { pkill -CONT Runner.Listener; }

stop_when_idle() {
  while on_battery; do
    while on_battery && job_running; do sleep "${POLL_SECONDS:-10}"; done
    on_battery || return 0
    freeze_listener
    if ! job_running; then
      launchctl bootout "$service" || true
      thaw_listener || true
      return 0
    fi
    thaw_listener
  done
}

if on_battery; then
  launchctl disable "$service"
  stop_when_idle
fi

if ! on_battery; then
  thaw_listener || true
  launchctl enable "$service"
  launchctl print "$service" > /dev/null 2>&1 || launchctl bootstrap system "$plist"
fi
