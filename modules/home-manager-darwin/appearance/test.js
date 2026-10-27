ObjC.import("Foundation");

const MINUTE = 60000;
const TOLERANCE = 2 * MINUTE;
const COLOGNE = [50.9375, 6.9603];
const TROMSO = [69.6492, 18.9553];

function loadAppearance() {
  const argv = ObjC.deepUnwrap($.NSProcessInfo.processInfo.arguments);
  const testPath = argv.find((arg) => arg.endsWith("test.js"));
  const directory = testPath.substring(0, testPath.lastIndexOf("/") + 1);
  const source = ObjC.unwrap(
    $.NSString.stringWithContentsOfFileEncodingError(directory + "appearance.js", $.NSUTF8StringEncoding, null),
  );
  return eval(`(function () {
    ${source}
    return { sunTimes, latestSunEvent, appearanceFor, parseState, parseLocation, currentLocation, runWithTimeout, applyAppearance };
  })()`);
}

const {
  sunTimes,
  latestSunEvent,
  appearanceFor,
  parseState,
  parseLocation,
  currentLocation,
  runWithTimeout,
  applyAppearance,
} = loadAppearance();

const HOUR = 60 * MINUTE;
const NOW = utc("2026-10-25T12:00:00Z");

function countingLocate(location) {
  const locate = () => {
    locate.calls++;
    return location;
  };
  locate.calls = 0;
  return locate;
}

function failingLocate() {
  throw new Error("location unavailable");
}

function assertThrows(action, message) {
  try {
    action();
  } catch (error) {
    return;
  }
  throw new Error(`${message}: expected an error`);
}

function utc(isoString) {
  return Date.parse(isoString);
}

function assertEqual(actual, expected, message) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`${message}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

function assertNear(actual, expected, message) {
  if (typeof actual !== "number" || Math.abs(actual - expected) > TOLERANCE) {
    throw new Error(`${message}: expected ${new Date(expected).toISOString()}, got ${actual === null ? null : new Date(actual).toISOString()}`);
  }
}

const tests = {
  test_sun_times_cologne() {
    const references = [
      ["2026-10-24", "06:10:33", "16:21:17"],
      ["2026-10-25", "06:12:16", "16:19:20"],
      ["2026-03-29", "05:15:13", "17:59:35"],
      ["2026-06-21", "03:18:14", "19:49:42"],
      ["2026-12-21", "07:32:52", "15:27:33"],
    ];
    for (const [day, sunrise, sunset] of references) {
      const times = sunTimes(...COLOGNE, utc(`${day}T00:00:00Z`));
      assertNear(times.sunrise, utc(`${day}T${sunrise}Z`), `sunrise ${day}`);
      assertNear(times.sunset, utc(`${day}T${sunset}Z`), `sunset ${day}`);
    }
  },

  test_polar_night_has_no_events() {
    assertEqual(sunTimes(...TROMSO, utc("2026-12-21T00:00:00Z")), { sunrise: null, sunset: null }, "sun times");
    assertEqual(latestSunEvent(...TROMSO, utc("2026-12-21T12:00:00Z")), null, "latest event");
  },

  test_latest_event_after_sunset() {
    const event = latestSunEvent(...COLOGNE, utc("2026-10-25T18:00:00Z"));
    assertEqual(event.kind, "sunset", "kind");
    assertNear(event.time, utc("2026-10-25T16:19:20Z"), "time");
  },

  test_latest_event_before_sunrise() {
    const event = latestSunEvent(...COLOGNE, utc("2026-10-25T05:00:00Z"));
    assertEqual(event.kind, "sunset", "kind");
    assertNear(event.time, utc("2026-10-24T16:21:17Z"), "time");
  },

  test_sleep_across_several_events() {
    const event = latestSunEvent(...COLOGNE, utc("2026-10-26T12:00:00Z"));
    assertEqual(event.kind, "sunrise", "kind");
    assertNear(event.time, sunTimes(...COLOGNE, utc("2026-10-26T00:00:00Z")).sunrise, "time");
  },

  test_appearance_for() {
    const sunset = { kind: "sunset", time: utc("2026-10-25T16:19:20Z") };
    const sunrise = { kind: "sunrise", time: utc("2026-10-25T06:12:16Z") };
    assertEqual(appearanceFor(sunset, undefined), "dark", "first sunset");
    assertEqual(appearanceFor(sunrise, undefined), "light", "first sunrise");
    assertEqual(appearanceFor(sunset, { kind: "sunset", time: sunset.time }), null, "manual switch holds");
    assertEqual(appearanceFor(sunset, { kind: "sunset", time: sunset.time - 10 * MINUTE }), null, "location shift");
    assertEqual(appearanceFor(sunset, { kind: "sunrise", time: sunset.time - 10 * MINUTE }), "dark", "other kind");
    assertEqual(appearanceFor(sunset, { kind: "sunset", time: sunset.time - 1440 * MINUTE }), "dark", "next day");
    assertEqual(appearanceFor(null, { kind: "sunset", time: sunset.time }), null, "no event");
  },

  test_parse_state() {
    assertEqual(parseState(null), {}, "missing file");
    assertEqual(parseState("not json"), {}, "corrupt file");
    assertEqual(
      parseState('{"lastEvent":{"kind":"sunset","time":1}}'),
      { lastEvent: { kind: "sunset", time: 1 } },
      "valid file",
    );
  },

  test_parse_location() {
    assertEqual(parseLocation("50.943829 6.941043\n"), { latitude: 50.943829, longitude: 6.941043 }, "coordinates");
    assertThrows(() => parseLocation("kCLErrorDomain error 0"), "error output");
  },

  test_uses_cached_location_within_hour() {
    const locate = countingLocate({ latitude: 3, longitude: 4 });
    const state = { latitude: 1, longitude: 2, attemptedAt: NOW - HOUR + 1 };
    assertEqual(currentLocation(state, NOW, locate), state, "location");
    assertEqual(locate.calls, 0, "locate calls");
  },

  test_refreshes_location_after_hour() {
    const state = { latitude: 1, longitude: 2, attemptedAt: NOW - HOUR };
    const location = currentLocation(state, NOW, countingLocate({ latitude: 3, longitude: 4 }));
    assertEqual(location, { latitude: 3, longitude: 4, attemptedAt: NOW }, "location");
  },

  test_rounds_location_to_one_decimal() {
    const location = currentLocation({}, NOW, countingLocate({ latitude: 50.943829, longitude: -6.951043 }));
    assertEqual(location, { latitude: 50.9, longitude: -7, attemptedAt: NOW }, "location");
  },

  test_falls_back_to_cached_location() {
    const state = { latitude: 1, longitude: 2, attemptedAt: NOW - 2 * HOUR };
    assertEqual(currentLocation(state, NOW, failingLocate), { latitude: 1, longitude: 2, attemptedAt: NOW }, "location");
  },

  test_failed_attempt_waits_an_hour() {
    const locate = countingLocate({ latitude: 3, longitude: 4 });
    currentLocation({ latitude: 1, longitude: 2, attemptedAt: NOW - MINUTE }, NOW, locate);
    assertEqual(locate.calls, 0, "locate calls");
  },

  test_retries_every_run_until_first_location() {
    const location = currentLocation({ attemptedAt: NOW - MINUTE }, NOW, countingLocate({ latitude: 3, longitude: 4 }));
    assertEqual(location, { latitude: 3, longitude: 4, attemptedAt: NOW }, "location");
  },

  test_no_location_ever_known() {
    assertEqual(currentLocation({}, NOW, failingLocate), { attemptedAt: NOW }, "location");
  },

  test_sets_appearance_before_turning_off_automatic_switching() {
    const calls = [];
    applyAppearance("dark", (dark) => calls.push(`dark=${dark}`), () => calls.push("disable"));
    assertEqual(calls, ["dark=true", "disable"], "calls");
  },

  test_keeps_automatic_switching_when_setting_appearance_fails() {
    const calls = [];
    const denied = () => {
      throw new Error("not authorized to send Apple events");
    };
    assertThrows(() => applyAppearance("light", denied, () => calls.push("disable")), "denied");
    assertEqual(calls, [], "calls");
  },

  test_run_with_timeout() {
    assertEqual(runWithTimeout(["/bin/echo", "hi"], 5000), "hi\n", "output");
    const start = Date.now();
    assertThrows(() => runWithTimeout(["/bin/sleep", "5"], 500), "hanging command");
    if (Date.now() - start > 1500) {
      throw new Error(`hanging command: took ${Date.now() - start} ms`);
    }
    assertThrows(() => runWithTimeout(["/usr/bin/false"], 5000), "failing command");
  },
};

function run() {
  const failures = [];
  for (const [name, test] of Object.entries(tests)) {
    try {
      test();
      console.log(`ok ${name}`);
    } catch (error) {
      console.log(`FAIL ${name}: ${error.message}`);
      failures.push(name);
    }
  }
  if (failures.length > 0) {
    throw new Error(`${failures.length} test(s) failed`);
  }
}
