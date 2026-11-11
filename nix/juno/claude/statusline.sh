#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
model=$(jq -r '.model.display_name // .model.id // "?"' <<<"$input")
model_id=$(jq -r '.model.id // ""' <<<"$input")
effort=$(jq -r '.effort.level // empty' <<<"$input")
tokens=$(jq -r '.context_window
  | if .current_usage then .current_usage | (.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens)
    else ((.used_percentage // 0) * (.context_window_size // 0) / 100 | floor) end' <<<"$input")

case "$model_id" in
  *opus* | *fable*) threshold=150000 ;;
  *) threshold=300000 ;;
esac

label="$model${effort:+ · $effort} · $((tokens / 1000))k"

if ((tokens >= threshold)); then
  printf '\033[33m%s · Wechsel empfohlen\033[0m' "$label"
else
  printf '%s' "$label"
fi
