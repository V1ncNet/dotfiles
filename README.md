# dotfiles

Nix flake for my machines: nix-darwin and Home Manager on `iris` (macOS),
standalone Home Manager on the Linux hosts.

| Host    | System         | Configuration                        |
|---------|----------------|--------------------------------------|
| `iris`  | aarch64-darwin | `darwinConfigurations.iris`          |
| `bach`  | aarch64-linux  | `homeConfigurations."vincent@bach"`  |
| `ceres` | x86_64-linux   | `homeConfigurations."vincent@ceres"` |

## Requirements

- `iris`: Apple Silicon, Nix with flakes enabled, [Homebrew](https://brew.sh)
  and a signed-in Mac App Store
- Other hosts: multi-user Nix, zsh as login shell and an SSH alias per host
  in `~/.ssh/config` on `iris`

## iris

### Setup

```bash
git clone git@github.com:V1ncNet/dotfiles.git ~/Code/vinado/dotfiles
```

```bash
sudo -i nix run nix-darwin -- switch --flake ~/Code/vinado/dotfiles#iris
```

The Linux builder can only build its customized image once it runs. On a
fresh machine, comment out `systems` and `config` of `nix.linux-builder` in
`darwin/iris/default.nix` for the first switch, then switch again.

Afterwards, install the tools that are not managed by Nix:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

```bash
fnm install --lts && fnm default lts-latest
```

### Commands

Apply the configuration:

```bash
sudo darwin-rebuild switch --flake ~/Code/vinado/dotfiles#iris
```

Build without applying:

```bash
nix build --no-link ~/Code/vinado/dotfiles#darwinConfigurations.iris.system
```

Update all inputs, then switch:

```bash
nix flake update --flake ~/Code/vinado/dotfiles
```

Roll back to the previous generation:

```bash
sudo darwin-rebuild --rollback
```

## Other hosts

### Setup

Once per host, as root:

```bash
echo 'trusted-users = root vincent' >> /etc/nix/nix.conf && systemctl restart nix-daemon
```

```bash
loginctl enable-linger vincent
```

Move existing dotfiles such as `~/.zprofile` out of the way, Home Manager
does not overwrite unmanaged files.

### Deploy from iris

Build locally, copy the closure and activate it, from within the repository:

```bash
nix run .#deploy -- bach
```

`ceres` is built with x86_64 emulation, which is slower.

Free disk space by deleting all old generations, which rules out a rollback:

```bash
nix run .#gc -- bach
```

Generations older than 7 days are also collected weekly.

### Switch on the host

The flake is fetched from GitHub, so only pushed commits take effect.

```bash
nix run home-manager -- switch --flake github:V1ncNet/dotfiles#vincent@$(hostname)
```

Afterwards:

```bash
home-manager switch --refresh --flake github:V1ncNet/dotfiles#vincent@$(hostname)
```

Roll back to the previous generation:

```bash
home-manager generations
```

```bash
/nix/store/<generation>/activate
```

## Hosts without Nix

For macOS machines that cannot or may not run Nix, GitHub Actions builds a
portable export on every push to `main`. It contains the Home Manager
modules shared by all hosts (zsh, Git, starship, fzf, zoxide, direnv,
less/bat, vim) and those shared by all Macs (fnm, Ghostty configuration),
but nothing specific to `iris`.

### Setup

Requires [Homebrew](https://brew.sh).

```bash
curl -fsSL https://github.com/V1ncNet/dotfiles/releases/download/portable/portable.tar.gz | tar -xz
```

```bash
brew bundle --file dotfiles-portable/Brewfile
```

Try the export in a throwaway home directory first, which shows startup
errors without touching the real one:

```bash
T=$(mktemp -d); HOME=$T dotfiles-portable/install.sh; HOME=$T zsh -il
```

```bash
dotfiles-portable/install.sh
```

`install.sh` refuses to run until the `Brewfile` is satisfied and moves
differing existing files to `~/.dotfiles-backup/<timestamp>/`. To go back,
copy the backup into the home directory. Repeat the same steps to update.

Machine-specific settings survive updates in these files, which
`install.sh` creates empty and never overwrites:

- `~/.config/zsh/local.zsh`: PATH entries, exports and tool setup, sourced
  last. Take them from backed up zsh files, but not their oh-my-zsh setup.
- `~/.config/git/local`: Git settings such as a work email or signing key.
- `~/.config/zsh/secrets.zsh`: secrets.

### Build locally

```bash
nix build .#portable
```

## Notes

- Secrets go into `~/.config/zsh/secrets.zsh` as `export NAME=…`. The file
  is created on first switch and never tracked.
- `.envrc` files may override `JAVA_HOME` and other variables per project.
- Node follows `.nvmrc`, install missing versions with `fnm install`.
- Terminal colors live in `themes/claude.nix`, all other tools use the ANSI
  slots.
- Claude Code defaults in `darwin/iris/claude-code.nix` are merged into
  `~/.claude/settings.json` on switch, local changes win.
