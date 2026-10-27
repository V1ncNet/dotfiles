const DAY = 86400000;
const UNIX_EPOCH_JULIAN_DAY = 2440587.5;
const J2000 = 2451545;
const SUN_EVENT_ALTITUDE = -0.833;
const EARTH_AXIAL_TILT = 23.4397;
const SAME_EVENT_WINDOW = 1800000;

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

function run() {}
