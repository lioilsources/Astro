import 'model.dart';
import 'sun.dart';
import 'time.dart';

/// Chaldean order, slowest to fastest: rulers of consecutive planetary hours.
const chaldeanOrder = [Body.saturn, Body.jupiter, Body.mars, Body.sun, Body.venus, Body.mercury, Body.moon];

/// Ruler of the weekday ([DateTime.monday] … [DateTime.sunday]).
Body dayRulerOfWeekday(int weekday) => switch (weekday) {
      DateTime.monday => Body.moon,
      DateTime.tuesday => Body.mars,
      DateTime.wednesday => Body.mercury,
      DateTime.thursday => Body.jupiter,
      DateTime.friday => Body.venus,
      DateTime.saturday => Body.saturn,
      _ => Body.sun,
    };

/// One of the 24 unequal hours of a planetary day.
class PlanetaryHour {
  final Body ruler;

  /// 1–12 day hours (sunrise → sunset), 13–24 night hours (sunset → next sunrise).
  final int number;

  /// Julian Days UT.
  final double start;
  final double end;
  const PlanetaryHour(this.ruler, this.number, this.start, this.end);

  bool get isDay => number <= 12;
  bool covers(double jd) => jd >= start && jd < end;
  @override
  String toString() => '#$number ${ruler.name} [$start … $end)';
}

/// A planetary day: from sunrise of a local date to the next sunrise.
class PlanetaryDay {
  /// Local civil date at the place (its weekday gives the ruler).
  final int year, month, day;
  final Body ruler;
  final double sunrise;
  final double sunset;
  final double nextSunrise;
  final List<PlanetaryHour> hours;

  const PlanetaryDay._(this.year, this.month, this.day, this.ruler, this.sunrise, this.sunset, this.nextSunrise, this.hours);

  bool covers(double jd) => jd >= sunrise && jd < nextSunrise;

  /// Length of one day hour and one night hour, in days.
  double get dayHourLength => (sunset - sunrise) / 12;
  double get nightHourLength => (nextSunrise - sunset) / 12;

  PlanetaryHour? hourAt(double jd) => hours.where((h) => h.covers(jd)).firstOrNull;
}

/// Planetary hours (plan 10.2). Day and night are each split into twelve
/// equal parts; the first day hour belongs to the ruler of the weekday and the
/// rest follow the Chaldean order. Where the Sun does not rise or set
/// (polar day or night) there are no hours: the functions return null.
class PlanetaryHours {
  PlanetaryHours._();

  /// The planetary day that starts at sunrise of the local date at [lat], [lon].
  static PlanetaryDay? day(int year, int month, int day, double lat, double lon) {
    final m = SunRiseSet.localMidnight(year, month, day, lon);
    final c = SunRiseSet.crossings(m, m + 2.2, lat, lon);
    final rise = c.indexWhere((x) => x.rising && x.jd < m + 1);
    if (rise < 0) return null;
    final set = c.indexWhere((x) => !x.rising, rise + 1);
    if (set < 0 || set != rise + 1) return null;
    final next = c.indexWhere((x) => x.rising, set + 1);
    if (next < 0 || next != set + 1) return null;
    final r = c[rise].jd, s = c[set].jd, n = c[next].jd;
    // Polar edge: a day that is not followed by a normal night within a day.
    if (n - r > 1.25) return null;
    final ruler = dayRulerOfWeekday(DateTime.utc(year, month, day).weekday);
    final first = chaldeanOrder.indexOf(ruler);
    final hd = (s - r) / 12, hn = (n - s) / 12;
    final hours = [
      for (var i = 0; i < 24; i++)
        PlanetaryHour(
          chaldeanOrder[(first + i) % 7],
          i + 1,
          i < 12 ? r + i * hd : s + (i - 12) * hn,
          i < 11 ? r + (i + 1) * hd : (i == 11 ? s : (i < 23 ? s + (i - 11) * hn : n)),
        ),
    ];
    return PlanetaryDay._(year, month, day, ruler, r, s, n, hours);
  }

  /// The planetary day containing [jdUt] (before sunrise it is the previous date's).
  static PlanetaryDay? dayAt(double jdUt, double lat, double lon) {
    final c = calendarFromJd(jdUt + lon / 360, calendar: CalendarKind.gregorian);
    var date = DateTime.utc(c.year, c.month, c.day.floor());
    for (var i = 0; i < 3; i++) {
      final d = PlanetaryHours.day(date.year, date.month, date.day, lat, lon);
      if (d == null) return null;
      if (jdUt < d.sunrise) {
        date = date.subtract(const Duration(days: 1));
      } else if (jdUt >= d.nextSunrise) {
        date = date.add(const Duration(days: 1));
      } else {
        return d;
      }
    }
    return null;
  }

  /// The planetary hour at [jdUt], or null where there are no hours.
  static PlanetaryHour? hourAt(double jdUt, double lat, double lon) => dayAt(jdUt, lat, lon)?.hourAt(jdUt);
}
