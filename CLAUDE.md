# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Nix flake for three hosts: nix-darwin + Home Manager on `iris` (aarch64-darwin, the machine this repo is edited on), standalone Home Manager on the Linux hosts `bach` (aarch64-linux) and `ceres` (x86_64-linux). See README.md for first-time setup per host.

## Commands

Run from the repository root. The flake only sees files tracked by git, so `git add` new `.nix` files before building.

```bash
# Build iris without applying (the main check after an edit)
nix build --no-link .#darwinConfigurations.iris.system

# Apply on iris
sudo darwin-rebuild switch --flake .#iris

# Build a Linux host's Home Manager config (uses the nix-darwin linux-builder VM; ceres runs under x86_64 emulation and is slow)
nix build --no-link '.#homeConfigurations."vincent@bach".activationPackage'

# Build, copy and activate on a Linux host over SSH / collect garbage there
nix run .#deploy -- bach
nix run .#gc -- bach

# Update inputs
nix flake update
```

Switching on a Linux host itself (`home-manager switch --flake github:V1ncNet/dotfiles#vincent@<host>`) fetches from GitHub, so only pushed commits take effect.

## Architecture

- `flake.nix` wires inputs (nixpkgs unstable, nix-darwin, home-manager, mac-app-util) to three outputs: `darwinConfigurations` from `darwin/`, `homeConfigurations` from `nix/`, and `apps.aarch64-darwin` (`deploy`, `gc`) from `apps/`.
- **System level (nix-darwin, iris only):** `darwin/iris/default.nix` imports the shared system modules `modules/common` and `modules/zsh` plus iris-specific `system.nix`, `environment.nix` (system packages, fonts, `EDITOR`/`VISUAL`) and `homebrew.nix` (casks, taps, Mac App Store apps). It also configures the `nix.linux-builder` used to build the Linux hosts.
- **User level (Home Manager):** `modules/home-manager/default.nix` is a plain *list* of module paths (zsh, starship, git, vim, less, fzf), not a module. It is consumed by both `darwin/iris/home.nix` and `nix/base.nix` via `imports = (import <path>/modules/home-manager)`; iris appends its extra modules with `++ [ ... ]`. Put configuration shared by all hosts there, but keep it free of unfree packages (only iris sets `allowUnfree`, the Linux hosts use `nixpkgs.legacyPackages`) and of macOS specifics like `defaults`, `/opt/homebrew` or `ghostty-bin`; host-specific options go in `darwin/iris/home.nix` (plus `claude-code.nix`, `ghostty.nix`) or `nix/base.nix` / `nix/<host>.nix`. Home Manager merges list/string options like `programs.zsh.envExtra`, `initContent` and oh-my-zsh plugins across these files.
- **Linux hosts:** `nix/default.nix` defines `vincent@bach` and `vincent@ceres`, both importing `nix/base.nix` through their per-host file. `base.nix` sources the Nix daemon profile in zshenv so non-interactive SSH commands (used by the `deploy`/`gc` apps) find Nix.
- **Theming:** `themes/claude.nix` holds the terminal color palette (light/dark) and is only consumed by `darwin/iris/ghostty.nix`. Other tools (vim, starship, fzf, less, bat, mdcat, taskwarrior) deliberately use ANSI color slots so they follow the terminal theme — don't hardcode hex colors in them. Taskwarrior switches between its `dark-16` and `light-16` themes via a wrapper in `darwin/iris/home.nix`.

## Conventions

- Secrets live in the untracked `~/.config/zsh/secrets.zsh` (created from a template by a Home Manager activation script in `modules/home-manager/zsh.nix`); never put them in the repo.
- `~/.claude/settings.json` is generated read-only from `darwin/iris/claude-code.nix`; change Claude Code settings there. Claude Code itself and Node versions (`fnm`) are installed outside Nix.
- On iris, Nix paths take precedence over Homebrew in `PATH`.
- Set global environment variables and paths with `home.sessionVariables` / `home.sessionPath`, which are applied once per session. Don't assign them in `programs.zsh.envExtra`: it runs in every shell and would undo per-project `direnv` overrides (e.g. `JAVA_HOME` from a `.envrc`) in nested shells.
- Home Manager refuses to overwrite unmanaged files. Before switching or deploying a change that adds a managed file, check whether the target already exists on the host.
- Nix doesn't repeat evaluation warnings for cached evaluations. When checking a build for warnings, make sure it was actually re-evaluated after the change.
- Switching iris requires `sudo`; leave running the switch to Vincent.
- Commit messages are short imperative sentences without prefixes (e.g. "Collect garbage weekly on Linux hosts").
- Follow-up corrections to unpushed commits are made with `git commit --fixup`. Squash and push only when asked.
