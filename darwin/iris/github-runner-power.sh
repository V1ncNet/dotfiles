#!/bin/bash
set -u

service="system/${RUNNER_LABEL:?}"
plist="/Library/LaunchDaemons/${RUNNER_LABEL}.plist"

on_battery() { pmset -g batt | grep -q "Battery Power"; }
job_running() { pgrep -q Runner.Worker; }

if on_battery; then
  launchctl disable "$service"
  while on_battery && job_running; do sleep "${POLL_SECONDS:-10}"; done
fi

if on_battery; then
  launchctl bootout "$service" || true
else
  launchctl enable "$service"
  launchctl print "$service" > /dev/null 2>&1 || launchctl bootstrap system "$plist"
fi
