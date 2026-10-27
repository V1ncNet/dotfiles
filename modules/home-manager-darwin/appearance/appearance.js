ObjC.import("Foundation");

const DAY = 86400000;
const HOUR = 3600000;
const UNIX_EPOCH_JULIAN_DAY = 2440587.5;
const J2000 = 2451545;
const SUN_EVENT_ALTITUDE = -0.833;
const EARTH_AXIAL_TILT = 23.4397;
const SAME_EVENT_WINDOW = 1800000;
const LOCATION_REFRESH_INTERVAL = HOUR;
const LOCATION_TIMEOUT = 15000;
const POLL_INTERVAL_SECONDS = 0.05;
const CORE_LOCATION_CLI = "/opt/homebrew/bin/CoreLocationCLI";
const SKYLIGHT = "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight";
const RTLD_LAZY = 1;

function radians(degrees) {
  return (degrees * Math.PI) / 180;
}

function degrees(radians) {
  return (radians * 180) / Math.PI;
}

function julianDayToEpoch(julianDay) {
  return (julianDay - UNIX_EPOCH_JULIAN_DAY) * DAY;
}

function sunTimes(latitude, longitude, utcDay) {
  const daysSinceJ2000 = Math.round(utcDay / DAY + UNIX_EPOCH_JULIAN_DAY + 0.5 - J2000);
  const meanSolarTime = daysSinceJ2000 - longitude / 360;
  const meanAnomaly = radians((357.5291 + 0.98560028 * meanSolarTime) % 360);
  const equationOfCenter =
    1.9148 * Math.sin(meanAnomaly) + 0.02 * Math.sin(2 * meanAnomaly) + 0.0003 * Math.sin(3 * meanAnomaly);
  const eclipticLongitude = radians((degrees(meanAnomaly) + equationOfCenter + 180 + 102.9372) % 360);
  const solarTransit =
    J2000 + meanSolarTime + 0.0053 * Math.sin(meanAnomaly) - 0.0069 * Math.sin(2 * eclipticLongitude);
  const declination = Math.asin(Math.sin(eclipticLongitude) * Math.sin(radians(EARTH_AXIAL_TILT)));
  const cosHourAngle =
    (Math.sin(radians(SUN_EVENT_ALTITUDE)) - Math.sin(radians(latitude)) * Math.sin(declination)) /
    (Math.cos(radians(latitude)) * Math.cos(declination));
  if (cosHourAngle < -1 || cosHourAngle > 1) {
    return { sunrise: null, sunset: null };
  }
  const hourAngleInDays = degrees(Math.acos(cosHourAngle)) / 360;
  return {
    sunrise: julianDayToEpoch(solarTransit - hourAngleInDays),
    sunset: julianDayToEpoch(solarTransit + hourAngleInDays),
  };
}

function latestSunEvent(latitude, longitude, now) {
  const today = Math.floor(now / DAY) * DAY;
  let latest = null;
  for (let offset = -2; offset <= 1; offset++) {
    const times = sunTimes(latitude, longitude, today + offset * DAY);
    for (const kind of ["sunrise", "sunset"]) {
      const time = times[kind];
      if (time !== null && time <= now && (latest === null || time > latest.time)) {
        latest = { kind, time };
      }
    }
  }
  return latest;
}

function appearanceFor(event, last) {
  if (event === null) {
    return null;
  }
  if (last !== undefined) {
    const alreadyActedUpon = event.time <= last.time;
    const sameEventShifted = event.kind === last.kind && event.time - last.time < SAME_EVENT_WINDOW;
    if (alreadyActedUpon || sameEventShifted) {
      return null;
    }
  }
  return event.kind === "sunset" ? "dark" : "light";
}

function parseState(text) {
  try {
    const state = JSON.parse(text);
    return state !== null && typeof state === "object" && !Array.isArray(state) ? state : {};
  } catch (error) {
    return {};
  }
}

function parseLocation(output) {
  const match = /^\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s*$/.exec(output);
  if (match === null) {
    throw new Error(`unexpected CoreLocationCLI output: ${output.trim()}`);
  }
  return { latitude: Number(match[1]), longitude: Number(match[2]) };
}

function hasCoordinates(location) {
  return typeof location.latitude === "number" && typeof location.longitude === "number";
}

function roundToTenth(coordinate) {
  return Math.round(coordinate * 10) / 10;
}

function currentLocation(state, now, locate) {
  const cached = hasCoordinates(state) ? { latitude: state.latitude, longitude: state.longitude } : {};
  const refreshDue =
    !hasCoordinates(state) || state.attemptedAt === undefined || now - state.attemptedAt >= LOCATION_REFRESH_INTERVAL;
  if (!refreshDue) {
    return { ...cached, attemptedAt: state.attemptedAt };
  }
  try {
    const { latitude, longitude } = locate();
    return { latitude: roundToTenth(latitude), longitude: roundToTenth(longitude), attemptedAt: now };
  } catch (error) {
    console.log(`Location unavailable: ${error.message}`);
    return { ...cached, attemptedAt: now };
  }
}

function readPipe(pipe) {
  const data = pipe.fileHandleForReading.readDataToEndOfFile;
  return $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;
}

function runWithTimeout(argv, timeoutMs) {
  const task = $.NSTask.alloc.init;
  const output = $.NSPipe.pipe;
  const errors = $.NSPipe.pipe;
  task.executableURL = $.NSURL.fileURLWithPath(argv[0]);
  task.arguments = $(argv.slice(1));
  task.standardOutput = output;
  task.standardError = errors;
  if (!task.launchAndReturnError(null)) {
    throw new Error(`cannot run ${argv[0]}`);
  }
  const deadline = Date.now() + timeoutMs;
  while (task.running) {
    if (Date.now() >= deadline) {
      task.terminate;
      throw new Error(`${argv[0]} timed out after ${timeoutMs} ms`);
    }
    delay(POLL_INTERVAL_SECONDS);
  }
  if (task.terminationStatus !== 0) {
    throw new Error(`${argv[0]} failed: ${readPipe(errors).trim()}`);
  }
  return readPipe(output);
}

function locate() {
  return parseLocation(runWithTimeout([CORE_LOCATION_CLI, "--format", "%latitude %longitude"], LOCATION_TIMEOUT));
}

function environmentVariable(name) {
  const value = $.NSProcessInfo.processInfo.environment.objectForKey(name);
  return value.isNil() ? undefined : value.js;
}

function stateDirectory() {
  const stateHome = environmentVariable("XDG_STATE_HOME") || `${$.NSHomeDirectory().js}/.local/state`;
  return `${stateHome}/appearance`;
}

function readState(path) {
  const text = $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null);
  return parseState(text.isNil() ? null : text.js);
}

function writeState(directory, path, state) {
  $.NSFileManager.defaultManager.createDirectoryAtPathWithIntermediateDirectoriesAttributesError(
    directory,
    true,
    $(),
    null,
  );
  $(JSON.stringify(state)).writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null);
}

function disableAutomaticAppearance() {
  try {
    ObjC.bindFunction("dlopen", ["void *", ["char *", "int"]]);
    $.dlopen(SKYLIGHT, RTLD_LAZY);
    ObjC.bindFunction("SLSGetAppearanceThemeSwitchesAutomatically", ["bool", []]);
    ObjC.bindFunction("SLSSetAppearanceThemeSwitchesAutomatically", ["void", ["bool"]]);
    if ($.SLSGetAppearanceThemeSwitchesAutomatically()) {
      $.SLSSetAppearanceThemeSwitchesAutomatically(false);
    }
  } catch (error) {
    console.log(`Could not turn off automatic appearance, turn it off in System Settings: ${error.message}`);
  }
}

function setDarkMode(dark) {
  Application("System Events").appearancePreferences.darkMode = dark;
}

function applyAppearance(appearance, setDark, disableAutomatic) {
  setDark(appearance === "dark");
  disableAutomatic();
}

function setAppearance(appearance) {
  applyAppearance(appearance, setDarkMode, disableAutomaticAppearance);
}

function run() {
  const now = new Date().getTime();
  const directory = stateDirectory();
  const path = `${directory}/state.json`;
  const state = readState(path);
  const location = currentLocation(state, now, locate);
  const nextState = { ...state, ...location };
  try {
    if (hasCoordinates(location)) {
      const event = latestSunEvent(location.latitude, location.longitude, now);
      const appearance = appearanceFor(event, state.lastEvent);
      if (appearance !== null) {
        setAppearance(appearance);
        nextState.lastEvent = event;
      }
    }
  } finally {
    if (JSON.stringify(nextState) !== JSON.stringify(state)) {
      writeState(directory, path, nextState);
    }
  }
}
