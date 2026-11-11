#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
subagent_type=$(jq -r '.tool_input.subagent_type // ""' <<<"$input")
model=$(jq -r '.tool_input.model // ""' <<<"$input")

agents_without_model_choice=(
  fork
  claude-code-guide
  statusline-setup
  feature-dev:code-architect
  feature-dev:code-explorer
  feature-dev:code-reviewer
)

if [[ -n "$model" ]]; then
  exit 0
fi
for agent in "${agents_without_model_choice[@]}"; do
  if [[ "$subagent_type" == "$agent" ]]; then
    exit 0
  fi
done

jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "Set `model` (and `effort`) explicitly, following the model table in ~/.claude/superpowers.md or the section Modellwahl in ~/.claude/CLAUDE.md."
  }
}'
