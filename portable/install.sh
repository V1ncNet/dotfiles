#!/usr/bin/env bash
set -euo pipefail

readonly placeholder="/__HOME__"
readonly exported_home="$(cd "$(dirname "$0")" && pwd)/home"
readonly backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
readonly staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT

stage() {
  local source="$1" staged="$2"
  cp "$source" "$staged"
  if grep -q "$placeholder" "$source"; then
    sed "s|$placeholder|$HOME|g" "$source" > "$staged"
  fi
}

back_up() {
  local relative="$1"
  mkdir -p "$(dirname "$backup/$relative")"
  mv "$HOME/$relative" "$backup/$relative"
}

install_file() {
  local relative="$1" target="$HOME/$1" staged="$staging/file"
  stage "$exported_home/$relative" "$staged"
  if [[ -e "$target" || -L "$target" ]] && ! cmp -s "$staged" "$target"; then
    back_up "$relative"
  fi
  mkdir -p "$(dirname "$target")"
  mv "$staged" "$target"
}

create_if_missing() {
  local file="$1" mode="$2"
  if [[ ! -e "$file" ]]; then
    mkdir -p "$(dirname "$file")"
    install -m "$mode" /dev/null "$file"
  fi
}

while IFS= read -r -d '' file; do
  install_file "${file#"$exported_home"/}"
done < <(find "$exported_home" -type f -print0)

create_if_missing "$HOME/.config/zsh/secrets.zsh" 600
create_if_missing "$HOME/.config/git/local" 644

if [[ -d "$backup" ]]; then
  echo "Replaced files were moved to $backup"
fi
