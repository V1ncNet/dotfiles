#!/usr/bin/env bash
set -euo pipefail

hook="$(dirname "$0")/require-agent-model.sh"

decision() {
  "$hook" <<<"$1" | jq -rs '.[0].hookSpecificOutput.permissionDecision // "allow"'
}

assert() {
  local expected=$1 input=$2
  local actual
  actual=$(decision "$input")
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL: expected $expected, got $actual for $input" >&2
    exit 1
  fi
}

assert deny '{"tool_input":{"subagent_type":"general-purpose","prompt":"x"}}'
assert deny '{"tool_input":{"prompt":"x"}}'
assert allow '{"tool_input":{"subagent_type":"general-purpose","model":"sonnet"}}'
assert allow '{"tool_input":{"subagent_type":"fork"}}'
assert allow '{"tool_input":{"subagent_type":"claude-code-guide"}}'
assert deny '{"tool_input":{"subagent_type":"Explore"}}'
echo OK
