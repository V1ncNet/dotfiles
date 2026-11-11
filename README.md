# dotfiles

Nix flake for my machines: nix-darwin and Home Manager on `iris` (macOS),
standalone Home Manager on the Linux hosts.

| Host   | System         | Configuration                       |
|--------|----------------|-------------------------------------|
| `iris` | aarch64-darwin | `darwinConfigurations.iris`         |
| `bach` | aarch64-linux  | `homeConfigurations."vincent@bach"` |
| `juno` | aarch64-linux  | `homeConfigurations."agent@juno"`   |

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
fnm install --latest && fnm default latest
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

### GitHub Actions runner

`darwin/iris/github-runner.nix` runs the self-hosted runner `ops-flake` for
`V1ncNet/ops` as the user `_github-runner`. A job-started hook refuses every
job except the workflow `flake.yml` on `main`, triggered by
`pull_request_target`.

On battery power the runner stays off, so GitHub reports it as `offline`
and the workflow falls back to its other runner. The daemon
`github-runner-ops-flake-power` reacts to power source changes (and runs
once at boot). On battery it disables the runner service, so it stays off
after a reboot, waits until no job is running and then stops it. On AC power it
enables and starts the runner again. Before the stop, the script freezes
the listener and looks for a job once more, so a job handed over in the
last moment finishes instead of being cut off. A stop can still cut off a
job in the few milliseconds between GitHub handing it over and its worker
process starting. A job queued for the runner but not yet assigned when
the runner goes offline stays queued until the runner is back. Test the
script with:

```bash
darwin/iris/test-github-runner-power.sh
```

A switch that changes the runner definition loads it regardless of the power
source. On battery, run `sudo launchctl kickstart system/org.nixos.github-runner-ops-flake-power`
afterwards.

The runner registers once with a registration token, which expires after an
hour. Changing `url`, `workDir` or the labels needs a new registration:

Run from the repository root:

```bash
cfg=.#darwinConfigurations.iris.config
state=$(nix eval --raw $cfg.launchd.daemons.github-runner-ops-flake.environment.RUNNER_ROOT)
token=$(nix eval --raw $cfg.services.github-runners.ops-flake.tokenFile)
sudo launchctl bootout system/org.nixos.github-runner-ops-flake
sudo find "$state" -mindepth 1 -delete
sudo install -o _github-runner -g _github-runner -m 0600 /dev/null "$token"
gh api -X POST repos/V1ncNet/ops/actions/runners/registration-token \
  --jq .token | sudo tee "$token" >/dev/null
sudo darwin-rebuild switch --flake .#iris
```

On a fresh machine, the user does not exist before the first switch, so
create the token file with owner and group `533` instead.

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

## juno

`juno` runs NixOS, which owns services, packages, `known_hosts`, the SSH
client configuration and everything outside `/home/agent`.
`homeConfigurations."agent@juno"` manages only files in `/home/agent` as the
user `agent`, no packages and no services. An assertion fails the build
otherwise. It provides:

- `~/.claude/CLAUDE.md`, `~/.claude/superpowers.md` and `~/.agents/AGENTS.md`,
  linked from the private flake input `agent-rules`
- the Claude Code hook and status line, and Claude Code defaults merged
  into `~/.claude/settings.json` (plugins, marketplaces, model settings)
- `~/.config/git/config` with SSH commit signing through
  `~/.ssh/id_ed25519.pub` and `~/.ssh/allowed_signers`, `gh` as credential
  helper and `https://github.com/` instead of `git@github.com:`

The access key for the model proxy is not part of it. It lives in
`~/.t3/service.env` together with `ANTHROPIC_BASE_URL`, because the Nix
store is world-readable. For the same reason, the rules from `agent-rules`
are readable by every user on the host.

`agent-rules` is fetched over SSH. Once the configuration is active, git
rewrites `git@github.com:` and `ssh://git@github.com/` to HTTPS and uses
the `gh` credential helper. Whoever builds the configuration needs read
access to that repository, and `nix flake update agent-rules` picks up new
rules.

The hook, the status line and the Git credential helper call `jq` and `gh`
from `PATH`, so NixOS has to provide both.

Home Manager refuses to overwrite unmanaged files, so move existing ones
away before the first switch, namely `~/.ssh/allowed_signers`,
`~/.config/git/config`, `~/.config/git/ignore`, `~/.agents/AGENTS.md` and
the managed files in `~/.claude`. During `gh auth login`, answer the prompt
to authenticate Git with no, because the Git configuration is read-only.

Run `gh auth login` before the first switch. The Git rewrite does not exist
yet then, so pass it once through the environment, as `agent`:

```bash
GIT_CONFIG_COUNT=2 \
GIT_CONFIG_KEY_0=url.https://github.com/.insteadOf \
GIT_CONFIG_VALUE_0=ssh://git@github.com/ \
GIT_CONFIG_KEY_1=credential.https://github.com.helper \
GIT_CONFIG_VALUE_1='!gh auth git-credential' \
nix run home-manager -- switch --flake github:V1ncNet/dotfiles#agent@juno
```

Later switches need no variables:

```bash
home-manager switch --refresh --flake github:V1ncNet/dotfiles#agent@juno
```

The `deploy` and `gc` apps only cover `vincent@<host>`.

## Hosts without Nix

For macOS machines that cannot or may not run Nix, GitHub Actions builds a
portable export on every push to `main`. It contains the Home Manager
modules shared by all hosts (zsh, Git, starship, fzf, zoxide, direnv,
less/bat, vim) and those shared by all Macs (fnm, Ghostty configuration,
appearance switching at sunrise and sunset), but nothing specific to
`iris`.

### Setup

Requires [Homebrew](https://brew.sh).

```bash
curl -fsSL https://github.com/V1ncNet/dotfiles/releases/download/portable/setup.sh | bash
```

Without curl, `wget -qO-` works the same way. The script downloads the
export, installs its `Brewfile` and runs `install.sh`.

Try the export in a throwaway home directory first, which shows startup
errors without touching the real one. The `Brewfile` still gets
installed system-wide, and Homebrew downloads bottles again because its
cache lives in the home directory:

```bash
T=$(mktemp -d); curl -fsSL https://github.com/V1ncNet/dotfiles/releases/download/portable/setup.sh | HOME=$T bash; HOME=$T zsh -il
```

`install.sh` moves differing existing files to
`~/.dotfiles-backup/<timestamp>/`. To go back, copy the backup into the
home directory. Run the same command again to update.

`install.sh` also loads the export's launch agents. The appearance
switch reads the location through CoreLocationCLI, which has to be
allowed under System Settings > Privacy & Security > Location Services.
macOS asks on the first run, but the switch may still be off afterwards.
On that first run macOS also asks whether `osascript` may control System
Events.

Machine-specific settings survive updates in these files, which
`install.sh` creates empty and never overwrites:

- `~/.config/zsh/env.zsh`: PATH entries and exports, sourced once per
  session so that scripts and other non-interactive shells see them too.
  Nested shells skip the file, so `export` every variable. Append PATH
  entries with `path+=`, because login shells move the system
  directories ahead of anything prepended here.
- `~/.config/zsh/local.zsh`: interactive setup such as aliases, key
  bindings and completions, sourced last. PATH entries that have to
  come before the system directories also go here.

Take these from backed up zsh files, but not their oh-my-zsh setup.
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
