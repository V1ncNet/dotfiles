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

## Notes

- Secrets go into `~/.config/zsh/secrets.zsh` as `export NAME=…`. The file
  is created on first switch and never tracked.
- `.envrc` files may override `JAVA_HOME` and other variables per project.
- Node follows `.nvmrc`, install missing versions with `fnm install`.
- Terminal colors live in `themes/claude.nix`, all other tools use the ANSI
  slots.
- `~/.claude/settings.json` is read-only, change it in
  `darwin/iris/claude-code.nix`.
