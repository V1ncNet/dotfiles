#!/usr/bin/env bash
set -euo pipefail

readonly placeholder="/__HOME__"
readonly export_root="$(cd "$(dirname "$0")" && pwd)"
readonly exported_home="$export_root/home"
readonly backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
readonly ghostty_app_config="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
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

require_homebrew_packages() {
  if ! HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file "$export_root/Brewfile" > /dev/null; then
    echo "Homebrew packages are missing, run: brew bundle --file $export_root/Brewfile" >&2
    exit 1
  fi
}

shell_files_backed_up() {
  local file
  for file in .zshrc .zshenv .zprofile; do
    [[ -e "$backup/$file" ]] && return 0
  done
  return 1
}

require_homebrew_packages

while IFS= read -r -d '' file; do
  install_file "${file#"$exported_home"/}"
done < <(find "$exported_home" -type f -print0)

create_if_missing "$HOME/.config/zsh/secrets.zsh" 600
create_if_missing "$HOME/.config/git/local" 644
create_if_missing "$HOME/.config/zsh/local.zsh" 644

if [[ -d "$backup" ]]; then
  echo "Replaced files were moved to $backup"
fi

if shell_files_backed_up; then
  cat <<EOF
Move machine-specific PATH entries, exports and tool setup from the zsh
files in the backup into ~/.config/zsh/local.zsh. Leave out any
oh-my-zsh setup, the export brings its own.
EOF
fi

if [[ -e "$HOME/.gitconfig" ]]; then
  echo "Git also reads ~/.gitconfig, whose settings override ~/.config/git/config"
fi

if [[ -e "$ghostty_app_config" ]]; then
  echo "Ghostty also reads $ghostty_app_config, which may override ~/.config/ghostty/config"
fi
