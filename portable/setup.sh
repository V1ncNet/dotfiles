#!/usr/bin/env bash
set -euo pipefail

readonly release_url="https://github.com/V1ncNet/dotfiles/releases/download/portable/portable.tar.gz"

require_macos() {
  if [[ "$(uname -s)" != Darwin ]]; then
    echo "The export only supports macOS" >&2
    return 1
  fi
}

load_homebrew() {
  command -v brew > /dev/null && return
  local brew="${HOMEBREW_PREFIX:-/opt/homebrew}/bin/brew"
  if [[ -x "$brew" ]]; then
    eval "$("$brew" shellenv)"
    return
  fi
  echo "The export requires Homebrew, install it as described on https://brew.sh" >&2
  return 1
}

require_downloader() {
  if ! command -v curl > /dev/null && ! command -v wget > /dev/null; then
    echo "Downloading the export requires curl or wget" >&2
    return 1
  fi
}

download() {
  if command -v curl > /dev/null; then
    curl -fsSL "$1"
  else
    wget -qO- "$1"
  fi
}

main() {
  local url="${DOTFILES_PORTABLE_URL:-$release_url}"
  require_macos
  load_homebrew
  require_downloader

  download_dir="$(mktemp -d)"
  trap 'rm -rf "$download_dir"' EXIT

  if ! download "$url" > "$download_dir/portable.tar.gz"; then
    echo "Downloading the export from $url failed" >&2
    return 1
  fi
  tar -xzf "$download_dir/portable.tar.gz" -C "$download_dir"
  brew bundle --file "$download_dir/dotfiles-portable/Brewfile"
  "$download_dir/dotfiles-portable/install.sh"
}

main < /dev/null
