# Sun-based appearance switching

## Intent

macOS "Auto" appearance switches to Dark only around the end of civil
dusk, roughly half an hour after sunset. Until then a bright screen
glares in a room that is already dark.

The appearance should follow daylight at the device's location. Light
between sunrise and sunset, Dark otherwise. The switch happens at
sunset, not at the end of dusk, and in the morning only once the sun has
actually risen. Daylight saving time changes need no special handling,
because the schedule follows the sun.

This applies to iris (nix-darwin) and to Macs that run the portable
export. Both must be able to grant Automation and Location Services
prompts.

## Goals

- Switch to Light at sunrise and to Dark at sunset, computed for the
  device's current approximate location.
- Switch while the Mac is in use, without waiting for idle time.
- A manual switch by Vincent holds until the next sunrise or sunset.
  Only a sun event that is newer than the last one acted upon triggers a
  switch. If the Mac slept across several events, the most recent one
  wins after wake.
- Get the location from macOS Location Services through CoreLocationCLI.
  If no location is available, use the last known one.
- Ship on iris and in the portable export from the same Home Manager
  configuration.

## Non-goals

- Weather, ambient light sensor or brightness-based switching.
- Linux hosts.
- Configurable offsets, custom schedules or twilight angles.
- Polar day or night handling beyond "no event, no switch".

## Anti-goals

- IP geolocation or any other third-party location service. No location
  data leaves the machine.
- Deriving the location from the time zone. CET spans Spain to Poland, so
  the error reaches an hour.
- Fixed coordinates in the repository, which is public.
- Fighting the user. A manual switch must never be reverted before the
  next sun event.
- Fighting macOS. Apple's "Auto" must be off wherever this runs, or both
  mechanisms toggle against each other.

## Decided

- **Location source:** CoreLocationCLI [1], a signed app bundle that
  prints the location from Location Services. It is a Homebrew cask
  (`corelocationcli`) and not in nixpkgs. Add it to `homebrew.casks` in
  `darwin/iris/homebrew.nix` and to `casks` in `portable/brew.nix`. The
  cask links the binary to `/opt/homebrew/bin/CoreLocationCLI`.
- **Switching logic:** a JavaScript for Automation script run with
  `/usr/bin/osascript -l JavaScript`. It needs no Nix, Homebrew or Python
  at runtime, so it runs unchanged on both Macs. It sets the appearance
  through System Events (`appearance preferences`, `dark mode`).
- **Scheduling:** a user launchd agent that runs the script periodically
  and at load (login), so the state is right after wake and login.
- **Module placement:** a new module in `modules/home-manager-darwin/`,
  added to that directory's `default.nix` list. Shared by iris and the
  portable export.
- **Sun event definition:** standard sunrise and sunset, upper limb on
  the horizon with refraction (solar altitude -0.833°).

## Builder's calls (made by Claude, open to veto)

- **Interval:** the agent runs every 60 seconds, so the switch lands
  within a minute of the event. Once a location is known, it is
  refreshed at most once per hour. Between refreshes and whenever
  CoreLocationCLI fails or times out, the cached location is used. Until
  the first location arrives, every run tries again, so granting the
  Location Services prompt takes effect within a minute.
- **State:** last known location and the timestamp of the last sun event
  acted upon live under `~/.local/state/appearance/` (respect
  `XDG_STATE_HOME` if set). Plain text or JSON, the builder decides.
- **First run:** with no stored event, the script applies the most
  recent sun event. Events are stored as an absolute timestamp. A
  location change shifts the computed time of the same event slightly,
  so an event of the same kind within 30 minutes of the stored one
  counts as already acted upon and does not override a manual switch.
- **`launchctl` failures in `install.sh`** (for example in a session
  without GUI) print a warning and do not abort the install.
- **No location ever known:** do nothing and exit successfully, so
  Apple's "Auto" stays in charge until a first location arrives.
- **Disabling "Auto":** the script itself turns off Apple's automatic
  switching whenever it sets the appearance, rather than nix-darwin
  `system.defaults` or `targets.darwin.defaults`. Activation-time
  defaults do not reach the portable export, because `install.sh` only
  copies files. Measured on iris (Darwin 27) on 2026-10-27:
  - Setting `dark mode` through System Events leaves "Auto" on.
  - `defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool
    false` changes the preference file but not the live state.
    `SLSGetAppearanceThemeSwitchesAutomatically` still returned true.
  - Calling the private SkyLight function
    `SLSSetAppearanceThemeSwitchesAutomatically(false)` from JXA turns
    "Auto" off live. macOS then removes the preference key itself, and
    System Settings shows "Dark" after it is reopened. The function is
    loaded with `dlopen` on
    `/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight` and
    bound with `ObjC.bindFunction`.

  The script uses the SkyLight call and only calls it when
  `SLSGetAppearanceThemeSwitchesAutomatically` reports "Auto" as on. It
  is a private API that a future macOS may remove. If the symbol is
  missing, the script still sets the appearance and logs a warning, and
  "Auto" has to be turned off by hand in System Settings.
- **No personal data in the repository.** Code, tests, commits and
  documentation contain no real coordinates, places or habits of the
  owner. Test fixtures use public reference cities.

## Constraints

- **Permissions:** two one-time macOS prompts are expected, Location
  Services for CoreLocationCLI and Automation for `osascript` controlling
  System Events. Verify that both prompts appear when the script runs
  from the launchd agent, not only from a terminal. Terminal-granted
  permissions may not carry over. Document the manual first run if one
  is needed.
- **Portable export:** Home Manager installs `launchd.agents` through an
  activation script (`setupLaunchAgents`), not through `home-files`.
  `portable/bundle.nix` and `bundle.py` only see `home-files`. So the
  agent plist must be added to the export explicitly and pass through
  `bundle.py`, so that store paths in it (such as the script path) are
  vendored and the `/__HOME__` placeholder is used. The existing leftover
  store path check only scans what it is given, so make sure the plist
  is part of it.
- **Installing the agent on portable hosts:** `install.sh` must place
  the plist in `~/Library/LaunchAgents` as a regular file, as Home
  Manager does for its agents, and (re)load it with `launchctl bootout` and
  `launchctl bootstrap gui/$UID`. Reinstalling must be idempotent.
- **iris:** use Home Manager's `launchd.agents` or an equivalent that
  copies the plist. Do not symlink a store plist into
  `~/Library/LaunchAgents`.
- **Unmanaged files:** Home Manager refuses to overwrite existing files.
  Check `~/Library/LaunchAgents` and the chosen script location on iris
  before switching.
- **PATH:** launchd agents get a minimal PATH. Call CoreLocationCLI by
  absolute path or set PATH in the agent.
- **No hardcoded colors or themes** are involved. vim, Taskwarrior and
  the Ghostty theme already follow the system appearance.
- Repo conventions from `CLAUDE.md` apply. Build with
  `nix build --no-link .#darwinConfigurations.iris.system` and
  `nix build .#portable`. Vincent runs the iris switch himself.

## Verification

- An automated check of the sun computation against reference sunrise
  and sunset times (within two minutes) for a few dates and a different
  location, including a date that crosses a DST change.
- An automated check of the decision rule. Given a last-acted event and
  the current time, the script switches only when a newer event exists,
  and picks the most recent one after a long gap.
- `portable/test-setup.sh` or a sibling test covers that `install.sh`
  installs and loads the agent and that a second run does not fail.
- `nix build .#portable` succeeds without leftover store references.
- Manual check on iris after the switch. The agent is loaded
  (`launchctl print gui/$UID/<label>`), both permission prompts were
  granted, and a manual switch survives until the next sun event.

## Left to the builder

- Agent label, script file name and location, log destination.
- How the script is tested (for example, pure functions in the JXA file
  exercised by a test runner via `osascript -l JavaScript`).
- Sun position algorithm (NOAA approximation is sufficient).
- How `bundle.nix` obtains the generated plist from the Home Manager
  configuration.

[1]: https://github.com/fulldecent/corelocationcli
