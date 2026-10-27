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
    return { sunTimes, latestSunEvent, appearanceFor };
  })()`);
}

const { sunTimes, latestSunEvent, appearanceFor } = loadAppearance();

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
