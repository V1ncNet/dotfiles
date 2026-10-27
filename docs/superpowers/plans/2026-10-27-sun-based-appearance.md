# Sun-based Appearance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Switch the macOS appearance to Light at sunrise and Dark at sunset for the device's location, on iris and in the portable export.

**Architecture:** A JXA script (`osascript -l JavaScript`) computes the most recent sun event from a cached CoreLocationCLI location and sets the appearance only when that event is newer than the last one it acted on. A Home Manager `launchd.agents` entry runs it every 60 s. The portable export copies the generated agent plist through `bundle.py` and loads it in `install.sh`.

**Tech Stack:** JavaScript for Automation, Home Manager `launchd.agents`, Homebrew cask `corelocationcli`, Bash, Python (`bundle.py`).

**Spec:** `docs/superpowers/specs/2026-10-27-sun-based-appearance-design.md`

## Global Constraints

- Light between sunrise and sunset, Dark otherwise. Sun event = solar altitude -0.833°.
- A manual switch holds until the next sun event. Act only on an event newer than the stored `lastEvent` that is not the same event shifted by a location change (same kind within 30 minutes).
- Location only from `/opt/homebrew/bin/CoreLocationCLI`. No network services, no time-zone fallback, no coordinates in the repo.
- Once coordinates are cached, location lookups are attempted at most once per hour (3 600 000 ms since the last attempt, successful or not). Without cached coordinates every run tries. The cached location is used otherwise and on failure. No location ever known means exit 0 without changes.
- "Auto" is turned off with `SLSSetAppearanceThemeSwitchesAutomatically(false)` from SkyLight, only when `SLSGetAppearanceThemeSwitchesAutomatically()` returns true. Missing symbol logs a warning and the switch still happens.
- Appearance is set via `Application("System Events").appearancePreferences.darkMode`.
- State in `${XDG_STATE_HOME:-$HOME/.local/state}/appearance/state.json`.
- No personal data in code, tests, commits or docs: no real coordinates, places or habits of the owner. Test fixtures use Cologne (50.9375, 6.9603) and Tromsø (69.6492, 18.9553). The location only lives in the local `state.json`.
- `launchctl` failures in `install.sh` warn and do not abort.
- Commit messages follow `~/.claude/CLAUDE.md` (English, Beams rules, no needless articles, `Co-Authored-By` trailer). Code without inline comments.
- Build checks: `nix build --no-link .#darwinConfigurations.iris.system` and `nix build .#portable`. New files must be `git add`ed before building. Vincent runs `darwin-rebuild switch` himself.

## Review Focus

1. CoreLocationCLI hangs (no permission answered, Wi-Fi off). Expected: the call is terminated after 15 s, the cached location is used and the next attempt waits an hour (or happens on the next run while no location is known). Tests in Task 3 (`runWithTimeout`, `locate` throws, attempt throttling).
2. Mac asleep across two or more sun events. Expected: after wake the most recent event wins. Test in Task 2.
3. No sunrise or sunset at all (polar night/day). Expected: no change, no crash. Test in Task 2.
4. DST change day. Expected: event times correct, because all math runs in UTC epoch ms. Test in Task 2 (Cologne 2026-10-25 and 2026-03-29).
5. Missing or corrupt `state.json`. Expected: treated as empty state, then overwritten. Test in Task 3.

---

### Task 1: Permission spike (main session, throwaway)

Verifies the two assumptions the design cannot settle on paper. Nothing from this task is committed.

- [ ] **Step 1:** Install the cask with `brew install --cask corelocationcli` and check `/opt/homebrew/bin/CoreLocationCLI --format '%latitude %longitude'` prints coordinates after granting the Location Services prompt.
- [ ] **Step 2:** Create a throwaway agent in `~/Library/LaunchAgents/spike.appearance.plist` that runs `/usr/bin/osascript -l JavaScript <scratchpad>/spike.js` once (`RunAtLoad`), with `StandardOutPath`/`StandardErrorPath` in the scratchpad. `spike.js` runs `doShellScript("/opt/homebrew/bin/CoreLocationCLI --format '%latitude %longitude'")` and sets `darkMode` to its current value via System Events. Load it with `launchctl bootstrap gui/501 …`.
- [ ] **Step 3:** Expected: the log shows coordinates and no error. If an Automation prompt for `osascript` appears, Vincent grants it. If CoreLocationCLI fails under launchd while it works in the terminal, stop and bring the finding back to Vincent before Task 2, because the design's location source then needs another launch path (for example `open -a CoreLocationCLI --stdout`).
- [ ] **Step 4:** `launchctl bootout gui/501/spike.appearance`, delete the plist and scratchpad files.

### Task 2: Sun events and decision rule

**Files:**
- Create: `modules/home-manager-darwin/appearance/appearance.js`
- Create: `modules/home-manager-darwin/appearance/test.js`
- Modify: `.github/workflows/ci.yml` (darwin job)

**Interfaces:**
- Produces, in `appearance.js` (top level holds only function declarations plus `run`):
  - `sunTimes(latitude: number, longitude: number, utcDay: number) -> { sunrise: number|null, sunset: number|null }`. `utcDay` is epoch ms of 00:00Z, results are epoch ms. `null` when the sun does not cross -0.833° that day.
  - `latestSunEvent(latitude: number, longitude: number, now: number) -> { kind: "sunrise"|"sunset", time: number } | null`. Latest event with `time <= now` among the UTC days `now-2 … now+1`.
  - `appearanceFor(event, last: { kind, time } | undefined) -> "dark"|"light"|null`. `null` if `event` is null, if `event.time <= last.time`, or if `event.kind === last.kind` and `event.time - last.time < 1800000` (same event, shifted by a location change).
- `test.js` loads `appearance.js` from the directory of its own path, taken from `ObjC.deepUnwrap($.NSProcessInfo.processInfo.arguments)` (JXA has no `__filename`), read with `$.NSString.stringWithContentsOfFileEncodingError`, and `eval`s it inside a function scope, so its `run` does not replace the test runner's `run`. Each failing assertion throws, which makes `osascript` exit non-zero.

- [ ] **Step 1: Write the failing tests** in `test.js`. Reference times come from the `astral` library.

```js
// Cologne 50.9375, 6.9603, tolerance 120 000 ms
test_sun_times_cologne:
  2026-10-24 sunrise 06:10:33Z sunset 16:21:17Z
  2026-10-25 sunrise 06:12:16Z sunset 16:19:20Z   // DST ends
  2026-03-29 sunrise 05:15:13Z sunset 17:59:35Z   // DST starts
  2026-06-21 sunrise 03:18:14Z sunset 19:49:42Z
  2026-12-21 sunrise 07:32:52Z sunset 15:27:33Z
test_polar_night_has_no_events:
  sunTimes(69.6492, 18.9553, 2026-12-21) -> { sunrise: null, sunset: null }
  latestSunEvent(69.6492, 18.9553, 2026-12-21T12:00Z) -> null
test_latest_event_after_sunset:
  latestSunEvent(Cologne, 2026-10-25T18:00Z) -> kind "sunset", time ≈ 16:19:20Z
test_latest_event_before_sunrise:
  latestSunEvent(Cologne, 2026-10-25T05:00Z) -> kind "sunset", time ≈ 2026-10-24 16:21:17Z
test_sleep_across_several_events:
  latestSunEvent(Cologne, 2026-10-26T12:00Z) -> kind "sunrise" of 2026-10-26
test_appearance_for:
  appearanceFor(sunset event, undefined) -> "dark"
  appearanceFor(sunrise event, undefined) -> "light"
  appearanceFor(event, { kind: event.kind, time: event.time }) -> null      // manual switch holds
  appearanceFor(event, { kind: event.kind, time: event.time - 600000 }) -> null   // location shift
  appearanceFor(sunset, { kind: "sunrise", time: sunset.time - 600000 }) -> "dark"
  appearanceFor(event, { kind: event.kind, time: event.time - 86400000 }) -> event's appearance
  appearanceFor(null, anything) -> null
```

- [ ] **Step 2:** Run `osascript -l JavaScript modules/home-manager-darwin/appearance/test.js`. Expected: non-zero exit, error naming a missing function.
- [ ] **Step 3:** Implement the three functions. NOAA solar position approximation in UTC (Julian day, declination, equation of time, hour angle for -0.833°). `acos` argument outside [-1, 1] yields `null`.
- [ ] **Step 4:** Run the test command again. Expected: exit 0.
- [ ] **Step 5:** Add a step `run: osascript -l JavaScript modules/home-manager-darwin/appearance/test.js` to the `darwin` job in `.github/workflows/ci.yml`, next to `portable/test-setup.sh`.
- [ ] **Step 6: Commit** `Compute sunrise and sunset for appearance switch`.

### Task 3: State, location and switching

**Files:**
- Modify: `modules/home-manager-darwin/appearance/appearance.js`
- Modify: `modules/home-manager-darwin/appearance/test.js`

**Interfaces:**
- Consumes: `latestSunEvent`, `appearanceFor` from Task 2.
- Produces:
  - `parseState(text: string|null) -> { latitude?, longitude?, attemptedAt?, lastEvent?: { kind, time } }`. Invalid JSON or null gives `{}`.
  - `parseLocation(output: string) -> { latitude: number, longitude: number }`. Parses `"<lat> <lon>"`, throws otherwise.
  - `currentLocation(state, now: number, locate: () => {latitude, longitude}) -> { latitude, longitude, attemptedAt } | null`. Calls `locate` when no coordinates are cached, when `attemptedAt` is missing or when `now - attemptedAt >= 3600000`, and then sets `attemptedAt = now` whether or not `locate` succeeds. If `locate` throws, keeps the cached coordinates, or returns `{ attemptedAt: now }` without coordinates when none are cached. `run` treats a result without coordinates as "no location".
  - `runWithTimeout(argv: string[], timeoutMs: number) -> string`. Runs the command with `$.NSTask` and an `NSPipe` for stdout, polls until it exits or the deadline passes, then calls `terminate` and throws. Returns stdout on exit status 0, throws otherwise. macOS has no `timeout` command, and `doShellScript` blocks until stdout closes, so neither is used.
  - `run()` wires it together: read state, `currentLocation`, `latestSunEvent`, `appearanceFor`, then on a result disable "Auto" and set `darkMode`, then write state (`lastEvent` only after a successful switch, location and `attemptedAt` whenever they changed). `run` creates the state directory with `NSFileManager createDirectoryAtPathWithIntermediateDirectoriesAttributesError` and writes `state.json` atomically. Uses `new Date().getTime()`.
  - `locate()` used by `run` is `parseLocation(runWithTimeout(["/opt/homebrew/bin/CoreLocationCLI", "--format", "%latitude %longitude"], 15000))`.

- [ ] **Step 1: Write the failing tests.**

```js
test_parse_state:
  parseState(null) -> {}
  parseState("not json") -> {}
  parseState('{"lastEvent":{"kind":"sunset","time":1}}') -> { lastEvent: { kind: "sunset", time: 1 } }
test_parse_location:
  parseLocation("50.943829 6.941043\n") -> { latitude: 50.943829, longitude: 6.941043 }
  parseLocation("kCLErrorDomain error 0") throws
test_uses_cached_location_within_hour:
  state { latitude: 1, longitude: 2, attemptedAt: now - 3599999 }, locate counts calls
  -> { latitude: 1, longitude: 2, attemptedAt: now - 3599999 }, locate called 0 times
test_refreshes_location_after_hour:
  attemptedAt: now - 3600000, locate returns { latitude: 3, longitude: 4 }
  -> { latitude: 3, longitude: 4, attemptedAt: now }
test_falls_back_to_cached_location:
  { latitude: 1, longitude: 2, attemptedAt: now - 7200000 }, locate throws
  -> { latitude: 1, longitude: 2, attemptedAt: now }
test_failed_attempt_waits_an_hour:
  state { latitude: 1, longitude: 2, attemptedAt: now - 60000 }, locate counts calls
  -> locate called 0 times
test_retries_every_run_until_first_location:
  state { attemptedAt: now - 60000 } without coordinates, locate returns { latitude: 3, longitude: 4 }
  -> { latitude: 3, longitude: 4, attemptedAt: now }
test_no_location_ever_known:
  state {}, locate throws -> { attemptedAt: now } without coordinates
test_run_with_timeout:
  runWithTimeout(["/bin/echo", "hi"], 5000) -> "hi\n"
  runWithTimeout(["/bin/sleep", "5"], 500) throws, and returns within 1500 ms
  runWithTimeout(["/usr/bin/false"], 5000) throws
```

- [ ] **Step 2:** Run the test command. Expected: non-zero exit for the missing functions.
- [ ] **Step 3:** Implement the pure functions and `runWithTimeout`, then `run()` and its I/O helpers (state path, System Events, SkyLight). SkyLight needs `ObjC.bindFunction("dlopen", ["void *", ["char *", "int"]])`, then `$.dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", 1)`, then `ObjC.bindFunction("SLSGetAppearanceThemeSwitchesAutomatically", ["bool", []])` and `ObjC.bindFunction("SLSSetAppearanceThemeSwitchesAutomatically", ["void", ["bool"]])`. `ObjC.import("Foundation")` may stay at the top level of `appearance.js`. A missing SkyLight symbol is caught and logged with `console.log` (stderr), the switch continues. Do not execute `run()` itself, since it changes the real appearance. That happens in Task 6.
- [ ] **Step 4:** Run the test command. Expected: exit 0.
- [ ] **Step 5: Commit** `Switch appearance at latest sun event`.

### Task 4: Home Manager module and cask

**Files:**
- Create: `modules/home-manager-darwin/appearance/default.nix`
- Modify: `modules/home-manager-darwin/default.nix` (add `./appearance`)
- Modify: `darwin/iris/homebrew.nix` (cask `corelocationcli` after `claude`, without reordering the list)
- Modify: `portable/brew.nix` (cask `corelocationcli`)
- Modify: `CLAUDE.md` (mention the appearance agent in the `home-manager-darwin` list and that `install.sh` loads launch agents)

**Interfaces:**
- Produces: `launchd.agents.appearance` with `enable = true`, `waitForNixStore = false` (otherwise Home Manager wraps the command in `/bin/wait4path /nix/store`, which never returns on hosts without Nix) and `config`:
  - `ProgramArguments = [ "/usr/bin/osascript" "-l" "JavaScript" "${./appearance.js}" ]`. Home Manager may still rewrite this into a launcher script in the store. That is fine as long as Task 5's checks pass.
  - `StartInterval = 60`, `RunAtLoad = true`
  - `StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/appearance.log"`
  - Label stays the default `org.nix-community.home.appearance`. Task 5 relies on the plist landing in `${config.home.activationPackage}/LaunchAgents/`.

- [ ] **Step 1:** Write the module and list entries.
- [ ] **Step 2:** `nix build --no-link .#darwinConfigurations.iris.system`. Expected: success. Then `nix build --no-link --print-out-paths .#darwinConfigurations.iris.config.home-manager.users.vincent.home.activationPackage` and check `<path>/LaunchAgents/org.nix-community.home.appearance.plist` exists and contains no `wait4path`.
- [ ] **Step 3:** On iris, check `~/Library/LaunchAgents/org.nix-community.home.appearance.plist` does not exist yet.
- [ ] **Step 4: Commit** `Run appearance switch as launchd agent`.

### Task 5: Ship agent in portable export

**Files:**
- Modify: `portable/bundle.nix` (pass `--launch-agents ${config.home.activationPackage}/LaunchAgents`)
- Modify: `portable/bundle.py` (`--launch-agents` copied through `Bundle.add` into `Library/LaunchAgents`, before `assert_self_contained`)
- Modify: `portable/install.sh` (load agents)
- Create: `portable/test-install.sh`
- Create: `portable/test-lib.sh` (shared `fail`, `assert_*`, `stub`, `run_test` loop, moved from `test-setup.sh`)
- Modify: `portable/test-setup.sh` (source `test-lib.sh`)
- Modify: `.github/workflows/ci.yml` (run `portable/test-install.sh`)

**Interfaces:**
- Consumes: the plist from Task 4.
- Produces: `install.sh` function `load_launch_agents`. It calls `launchctl` and `id` by name through `PATH`, never as `/bin/launchctl`, so the tests' stubs can never reach the real launchd. For each `*.plist` in `$exported_home/Library/LaunchAgents`, with `label` = file name without `.plist` and `domain` = `gui/$(id -u)`: `launchctl bootout "$domain/$label" 2>/dev/null && sleep 1` (errors ignored, the pause avoids "Bootstrap failed: 5" right after a bootout), then `launchctl bootstrap "$domain" "$HOME/Library/LaunchAgents/$label.plist"`. A failing bootstrap prints `Could not load launch agent <label>, run: launchctl bootstrap …` to stderr and continues. Runs after all files are installed.

- [ ] **Step 1:** Move `fail`, the `assert_*` helpers, `stub` and `run_test` from `test-setup.sh` into `test-lib.sh`, plus a function `run_all_tests` holding the `for test in $(declare -F …)` loop and the failure summary. `test-setup.sh` sources the lib at the top and calls `run_all_tests` as its last line. The helpers keep reading the globals `sandbox`, `status` and `failures`, so every test file sets `status` and writes `$sandbox/stderr` the way `run_setup` does. Run `portable/test-setup.sh`. Expected: exit 0. Commit `Extract shared helpers from portable setup test`.
- [ ] **Step 2: Write the failing tests** in `test-install.sh`, sourcing `test-lib.sh`. The sandbox holds an export with `Brewfile`, a copy of `install.sh` and `home/Library/LaunchAgents/test.agent.plist` containing `/__HOME__/x`. Stubs: `brew` (succeeds), `launchctl` (logs args), `id` (`echo 501`). `PATH` is the stub dir followed by `/usr/bin:/bin`.

```bash
test_installs_and_loads_launch_agent:
  status 0
  "$HOME/Library/LaunchAgents/test.agent.plist" is a regular file containing "$HOME/x"
  launchctl.log contains "bootstrap gui/501 $HOME/Library/LaunchAgents/test.agent.plist"
test_reinstall_reloads_launch_agent:
  run install.sh twice, both status 0
  launchctl.log line order: bootout gui/501/test.agent, bootstrap…, bootout…, bootstrap…
test_failed_bootstrap_only_warns:
  launchctl stub exits 5 on bootstrap
  status 0, stderr contains "test.agent"
```

- [ ] **Step 3:** Run `portable/test-install.sh`. Expected: failures for missing `bootstrap` calls.
- [ ] **Step 4:** Implement `load_launch_agents`, extend `bundle.py`/`bundle.nix`. If Task 1 showed that a manual first run is needed for the permission prompts, `install.sh` prints that command after loading the agents and `README.md` (section for hosts without Nix) documents it.
- [ ] **Step 5:** Run `portable/test-install.sh` and `portable/test-setup.sh`. Expected: both exit 0.
- [ ] **Step 6:** `nix build .#portable`, then `tar -tzf result/portable.tar.gz | grep LaunchAgents` lists `org.nix-community.home.appearance.plist`, and the extracted plist references `/__HOME__/.local/share/dotfiles/`. `grep -r /nix/store` over the extracted tree finds nothing, not even a bare `/nix/store` without hash. Expected: build success, no leftover store references.
- [ ] **Step 7: Commit** `Load launch agents from portable export`.

### Task 6: Verify on iris (main session, with Vincent)

- [ ] **Step 1:** Smoke test before the switch. Run `XDG_STATE_HOME=<scratchpad> osascript -l JavaScript modules/home-manager-darwin/appearance/appearance.js`. Expected: exit 0, `state.json` with location and `lastEvent`, appearance matches the sun. A second run changes nothing. This turns "Auto" off, which Vincent may want back on until the switch.
- [ ] **Step 2:** Vincent runs `sudo darwin-rebuild switch --flake .#iris`.
- [ ] **Step 3:** `launchctl print gui/501/org.nix-community.home.appearance` shows the job with `run interval = 60`. `~/Library/Logs/appearance.log` has no errors. Location and Automation permissions are granted (the Automation one may already exist from Task 1).
- [ ] **Step 4:** SkyLight reports "Auto" off and System Settings shows Light or Dark.
- [ ] **Step 5:** Vincent switches the appearance by hand. After two minutes it is unchanged. The next sun event switches it.
