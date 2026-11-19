import 'dart:math' as math;

import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

enum CalendarKind { gregorian, julian }

/// How the clock time of an event is to be read.
enum TimeBasis {
  /// Civil time of an IANA zone, including historical DST (tzdb).
  zone,

  /// Universal time as entered.
  ut,

  /// Local mean time of the given longitude: UT = time - lon/15 h.
  lmt,
}

/// Julian Day for a calendar date and UT fraction of day.
double julianDay(int year, int month, int day, double hourUt, {CalendarKind calendar = CalendarKind.gregorian}) {
  var y = year;
  var m = month;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  var b = 0;
  if (calendar == CalendarKind.gregorian) {
    final a = (y / 100).floor();
    b = 2 - a + (a / 4).floor();
  }
  return (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524.5 + hourUt / 24;
}

/// Calendar the date is most likely written in, absent other knowledge.
/// Before 15 Oct 1582 always Julian; later the country decides (manual switch).
CalendarKind defaultCalendar(int year, int month, int day) {
  if (year < 1582) return CalendarKind.julian;
  if (year == 1582 && (month < 10 || (month == 10 && day < 15))) return CalendarKind.julian;
  return CalendarKind.gregorian;
}

/// Calendar date (Gregorian after JD 2299160.5, Julian before) with fractional day.
({int year, int month, double day}) calendarFromJd(double jd, {CalendarKind? calendar}) {
  final j = jd + 0.5;
  final z = j.floor();
  final f = j - z;
  int a;
  final useGregorian = calendar == null ? z >= 2299161 : calendar == CalendarKind.gregorian;
  if (useGregorian) {
    final alpha = ((z - 1867216.25) / 36524.25).floor();
    a = z + 1 + alpha - (alpha / 4).floor();
  } else {
    a = z;
  }
  final b = a + 1524;
  final c = ((b - 122.1) / 365.25).floor();
  final d = (365.25 * c).floor();
  final e = ((b - d) / 30.6001).floor();
  final day = b - d - (30.6001 * e).floor() + f;
  final month = e < 14 ? e - 1 : e - 13;
  final year = month > 2 ? c - 4716 : c - 4715;
  return (year: year, month: month, day: day);
}

/// ΔT = TT - UT in seconds, polynomial expressions of Espenak & Meeus (NASA, 2006),
/// with the 2005–2050 branch replaced by a fit to observed IERS values.
double deltaTSeconds(double decimalYear) {
  final y = decimalYear;
  double p(double t, List<double> c) {
    var r = 0.0;
    for (var i = c.length - 1; i >= 0; i--) {
      r = r * t + c[i];
    }
    return r;
  }

  if (y < -500) {
    final u = (y - 1820) / 100;
    return -20 + 32 * u * u;
  }
  if (y < 500) {
    return p(y / 100, [10583.6, -1014.41, 33.78311, -5.952053, -0.1798452, 0.022174192, 0.0090316521]);
  }
  if (y < 1600) {
    return p((y - 1000) / 100, [1574.2, -556.01, 71.23472, 0.319781, -0.8503463, -0.005050998, 0.0083572073]);
  }
  if (y < 1700) {
    final t = y - 1600;
    return 120 - 0.9808 * t - 0.01532 * t * t + t * t * t / 7129;
  }
  if (y < 1800) {
    final t = y - 1700;
    return 8.83 + 0.1603 * t - 0.0059285 * t * t + 0.00013336 * t * t * t - math.pow(t, 4) / 1174000;
  }
  if (y < 1860) {
    return p(y - 1800, [13.72, -0.332447, 0.0068612, 0.0041116, -0.00037436, 0.0000121272, -0.0000001699, 0.000000000875]);
  }
  if (y < 1900) {
    final t = y - 1860;
    return 7.62 + 0.5737 * t - 0.251754 * t * t + 0.01680668 * t * t * t - 0.0004473624 * math.pow(t, 4) + math.pow(t, 5) / 233174;
  }
  if (y < 1920) {
    return p(y - 1900, [-2.79, 1.494119, -0.0598939, 0.0061966, -0.000197]);
  }
  if (y < 1941) {
    return p(y - 1920, [21.20, 0.84493, -0.076100, 0.0020936]);
  }
  if (y < 1961) {
    final t = y - 1950;
    return 29.07 + 0.407 * t - t * t / 233 + t * t * t / 2547;
  }
  if (y < 1986) {
    final t = y - 1975;
    return 45.45 + 1.067 * t - t * t / 260 - t * t * t / 718;
  }
  if (y < 2005) {
    return p(y - 2000, [63.86, 0.3345, -0.060374, 0.0017275, 0.000651814, 0.00002373599]);
  }
  if (y < 2030) {
    // Linear through observed values: 64.7 s (2005.0) → 69.2 s (2025.0).
    return 64.7 + (y - 2005) * 0.225;
  }
  if (y < 2150) {
    // Continue from 2030 towards the long-term parabola, blending linearly.
    final atStart = 64.7 + 25 * 0.225;
    final u = (y - 1820) / 100;
    final parabola = -20 + 32 * u * u - 0.5628 * (2150 - y);
    final w = (y - 2030) / 120;
    return atStart * (1 - w) + parabola * w;
  }
  final u = (y - 1820) / 100;
  return -20 + 32 * u * u;
}

double decimalYearOfJd(double jd) => 2000 + (jd - 2451545.0) / 365.25;

bool _tzReady = false;

void ensureTimeZones() {
  if (_tzReady) return;
  tzdata.initializeTimeZones();
  _tzReady = true;
}

/// A moment as written on a birth record or chosen by the user.
class LocalMoment {
  final int year;
  final int month;
  final int day;

  /// Clock time; null when unknown (the chart then uses local noon and no houses).
  final int? hour;
  final int? minute;
  final CalendarKind calendar;
  final TimeBasis basis;

  /// IANA zone name for [TimeBasis.zone], e.g. `Europe/Prague`.
  final String? zone;

  const LocalMoment({
    required this.year,
    required this.month,
    required this.day,
    this.hour,
    this.minute,
    this.calendar = CalendarKind.gregorian,
    this.basis = TimeBasis.zone,
    this.zone,
  });

  bool get timeKnown => hour != null;

  Map<String, Object?> toJson() => {
        'year': year,
        'month': month,
        'day': day,
        'hour': hour,
        'minute': minute,
        'calendar': calendar.name,
        'basis': basis.name,
        'zone': zone,
      };

  factory LocalMoment.fromJson(Map<String, Object?> j) => LocalMoment(
        year: j['year'] as int,
        month: j['month'] as int,
        day: j['day'] as int,
        hour: j['hour'] as int?,
        minute: j['minute'] as int?,
        calendar: CalendarKind.values.byName(j['calendar'] as String? ?? 'gregorian'),
        basis: TimeBasis.values.byName(j['basis'] as String? ?? 'zone'),
        zone: j['zone'] as String?,
      );
}

/// Result of converting a local moment to UT.
class ResolvedTime {
  final double jdUt;

  /// Offset from UT in hours that was applied (local = UT + offset).
  final double offsetHours;

  /// Basis actually used; a zone moment before the zone existed falls back to LMT.
  final TimeBasis basisUsed;

  /// Zone abbreviation (CET, CEST, LMT…) when known.
  final String? abbreviation;

  /// True when the local time was ambiguous or skipped by a DST change.
  final bool dstAmbiguous;

  const ResolvedTime({
    required this.jdUt,
    required this.offsetHours,
    required this.basisUsed,
    this.abbreviation,
    this.dstAmbiguous = false,
  });

  double get jdTt => jdUt + deltaTSeconds(decimalYearOfJd(jdUt)) / 86400;
}

/// Converts a local moment at longitude [lonDeg] (east positive) to UT.
ResolvedTime resolveMoment(LocalMoment m, double lonDeg) {
  final h = m.hour ?? 12;
  final mi = m.hour == null ? 0 : (m.minute ?? 0);
  final clock = h + mi / 60;
  switch (m.basis) {
    case TimeBasis.ut:
      return ResolvedTime(
        jdUt: julianDay(m.year, m.month, m.day, clock, calendar: m.calendar),
        offsetHours: 0,
        basisUsed: TimeBasis.ut,
        abbreviation: 'UT',
      );
    case TimeBasis.lmt:
      return _lmt(m, clock, lonDeg);
    case TimeBasis.zone:
      if (m.zone == null || m.calendar == CalendarKind.julian) return _lmt(m, clock, lonDeg);
      ensureTimeZones();
      final loc = tz.getLocation(m.zone!);
      final t = tz.TZDateTime(loc, m.year, m.month, m.day, h, mi);
      final zoneInfo = loc.timeZone(t.millisecondsSinceEpoch);
      // Before standard zones the tzdb offset is a city's mean time (LMT, PMT…),
      // recognisable by not being a multiple of 15 minutes → use the birth longitude.
      if (zoneInfo.offset.inSeconds % 900 != 0) return _lmt(m, clock, lonDeg);
      final ambiguous = _isAmbiguous(loc, t, m.year, m.month, m.day, h, mi);
      final utc = t.toUtc();
      final jd = julianDay(utc.year, utc.month, utc.day,
          utc.hour + utc.minute / 60 + utc.second / 3600);
      return ResolvedTime(
        jdUt: jd,
        offsetHours: zoneInfo.offset.inSeconds / 3600,
        basisUsed: TimeBasis.zone,
        abbreviation: zoneInfo.abbreviation,
        dstAmbiguous: ambiguous,
      );
  }
}

ResolvedTime _lmt(LocalMoment m, double clock, double lonDeg) => ResolvedTime(
      jdUt: julianDay(m.year, m.month, m.day, clock - lonDeg / 15, calendar: m.calendar),
      offsetHours: lonDeg / 15,
      basisUsed: TimeBasis.lmt,
      abbreviation: 'LMT',
    );

/// True when the wall-clock time maps to two instants (autumn change) or none (spring change).
bool _isAmbiguous(tz.Location loc, tz.TZDateTime t, int y, int mo, int d, int h, int mi) {
  final wall = DateTime.utc(y, mo, d, h, mi).millisecondsSinceEpoch;
  final ms = t.millisecondsSinceEpoch;
  final offsets = {loc.timeZone(ms - 3 * 3600000).offset, loc.timeZone(ms + 3 * 3600000).offset};
  if (offsets.length == 1) return false;
  var valid = 0;
  for (final o in offsets) {
    if (loc.timeZone(wall - o.inMilliseconds).offset == o) valid++;
  }
  return valid != 1;
}

/// Local civil time for a UT instant in an IANA zone (used for display of transits).
DateTime utToZone(double jdUt, String zone) {
  ensureTimeZones();
  final ms = ((jdUt - 2440587.5) * 86400000).round();
  final loc = tz.getLocation(zone);
  final t = tz.TZDateTime.fromMillisecondsSinceEpoch(loc, ms);
  return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
}

double jdFromDateTimeUtc(DateTime utc) => utc.toUtc().millisecondsSinceEpoch / 86400000 + 2440587.5;

DateTime dateTimeUtcFromJd(double jd) =>
    DateTime.fromMillisecondsSinceEpoch(((jd - 2440587.5) * 86400000).round(), isUtc: true);
