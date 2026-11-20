import 'angles.dart';
import 'aspects.dart';
import 'chart.dart';
import 'dignities.dart';
import 'ephemeris.dart';
import 'houses.dart';
import 'location.dart';
import 'model.dart';
import 'moon.dart';
import 'moon_aspects.dart';
import 'planetary_hours.dart';
import 'rules.dart';
import 'sun.dart';
import 'time.dart';
import 'track.dart';
import 'transits.dart';

/// Intents of the election search (plan 10.7): houses and planets that signify them.
enum ElectionIntent {
  relationship([7], [Body.venus]),
  contract([3, 7], [Body.mercury]),
  launch([1, 10], [Body.sun, Body.jupiter]),
  money([2], [Body.jupiter, Body.venus]),
  move([4], [Body.moon]),
  travel([3, 9], [Body.mercury, Body.jupiter]),
  study([3, 9], [Body.mercury]),
  application([10], [Body.sun, Body.jupiter]);

  final List<int> houses;
  final List<Body> planets;
  const ElectionIntent(this.houses, this.planets);

  /// Content id (`election/intent/{id}`).
  String get id => name;
}

/// Health intents: owner decision 19 — described in the glossary, never searched.
const electionHealthIntentIds = ['surgery'];

/// Verdict ids (`election/verdict/{id}`): the score bands of the rule file plus
/// `none` (nothing passed, least bad shown) and `health` (no search offered).
const electionVerdictIds = ['strong', 'good', 'weak', 'none', 'health'];

/// What to search for (plan 10.7).
class ElectionQuery {
  final ElectionIntent intent;

  /// First local date at [place].
  final int year, month, day;

  /// Length of the period, 1–[maxDays] days.
  final int days;
  final GeoLocation place;

  /// Natal chart for the personal layer; null = sky only.
  final Chart? natal;

  /// Allowed local clock hours 0–23 (sample start); null = any.
  final Set<int>? hours;

  /// Allowed weekdays [DateTime.monday]…[DateTime.sunday]; null = any.
  final Set<int>? weekdays;

  /// Void of course and the Moon's next aspect over Sun–Saturn only.
  final bool traditionalOnly;

  /// Null = default for the latitude of [place] (plan 3.3).
  final HouseSystem? houseSystem;
  final int maxWindows;

  /// At most this many windows starting on one local date (keeps the list varied).
  final int maxPerDay;

  const ElectionQuery({
    required this.intent,
    required this.year,
    required this.month,
    required this.day,
    required this.days,
    required this.place,
    this.natal,
    this.hours,
    this.weekdays,
    this.traditionalOnly = false,
    this.houseSystem,
    this.maxWindows = 10,
    this.maxPerDay = 3,
  });

  static const maxDays = 90;
}

/// The sky at one sample: what the rule predicates read.
class ElectionMoment {
  final double jd;
  final ElectionIntent intent;
  final Map<Body, double> lon;
  final Map<Body, LongitudeTrack> _tracks;
  final HouseResult houses;
  final MoonAspect? nextMoonAspect;

  /// A void-of-course period overlaps this sample.
  final bool voidOfCourse;
  final Body? hourRuler;

  /// Local calendar days between this sample and the nearest eclipse (null = none near).
  final int? eclipseDays;
  final Chart? natal;
  final double? dayTension;

  ElectionMoment._(this.jd, this.intent, this.lon, this._tracks, this.houses, this.nextMoonAspect, this.voidOfCourse, this.hourRuler,
      this.eclipseDays, this.natal, this.dayTension);

  double get asc => houses.asc;
  double get mc => houses.mc;
  Sign signOf(Body b) => Sign.ofLongitude(lon[b]!);
  bool retrograde(Body b) => b != Body.sun && b != Body.moon && (_tracks[b]?.speedAt(jd) ?? 0) < 0;
  int houseOf(Body b) => houses.houseOf(lon[b]!);
  Body get ascRuler => traditionalRuler(Sign.ofLongitude(asc));
  bool get moonWaxing => norm360(lon[Body.moon]! - lon[Body.sun]!) < 180;
}

/// Predicates of the conditions used in `content/rules/election.json`.
/// Rule params are documented in docs/scoring.md (Elekce).
final Map<String, RulePredicate<ElectionMoment>> electionPredicates = {
  'moon_void': (m, r) => m.voidOfCourse,
  'moon_waxing': (m, r) => m.moonWaxing,
  'moon_next_aspect': (m, r) {
    final a = m.nextMoonAspect;
    if (a == null) return false;
    final aspects = r.strings('aspects');
    return r.strings('bodies').contains(a.body.name) && (aspects.isEmpty || aspects.contains(a.type.name));
  },
  'on_angle': (m, r) {
    final l = m.lon[Body.values.byName(r.params['body'] as String)];
    if (l == null) return false;
    final orb = r.number('orb', 5);
    return [m.asc, m.mc, m.asc + 180, m.mc + 180].any((a) => angDist(l, a) <= orb);
  },
  'asc_ruler_dignified': (m, r) => isDignified(m.ascRuler, m.signOf(m.ascRuler)) && !m.retrograde(m.ascRuler),
  'asc_ruler_retrograde': (m, r) => m.retrograde(m.ascRuler),
  'asc_ruler_in_house': (m, r) => r.ints('houses').contains(m.houseOf(m.ascRuler)),
  'hour_of_intent_planet': (m, r) => m.hourRuler != null && m.intent.planets.contains(m.hourRuler),
  'intent_planet_state': (m, r) {
    final state = r.params['state'] as String;
    return m.intent.planets.any((b) => switch (state) {
          'retrograde' => m.retrograde(b),
          'dignified' => isDignified(b, m.signOf(b)),
          'fall' => dignityOf(b, m.signOf(b)) == Dignity.fall,
          'detriment' => dignityOf(b, m.signOf(b)) == Dignity.detriment,
          _ => throw ArgumentError('unknown state $state'),
        });
  },
  'in_intent_house': (m, r) => r.strings('bodies').any((id) {
        final b = Body.values.byName(id);
        return m.lon.containsKey(b) && m.intent.houses.contains(m.houseOf(b));
      }),
  'eclipse_near': (m, r) => m.eclipseDays != null && m.eclipseDays! <= r.number('days', 1),
  'moon_between': (m, r) {
    final l = m.lon[Body.moon]!;
    return l >= r.number('from', 195) && l < r.number('to', 225);
  },
  'moon_to_natal': (m, r) {
    final n = m.natal;
    if (n == null) return false;
    final orb = r.number('orb', 3);
    final types = [for (final a in r.strings('aspects')) AspectType.values.byName(a)];
    final moon = m.lon[Body.moon]!;
    for (final t in r.strings('targets')) {
      final target = t == 'asc' ? n.asc : n.positions[Body.values.byName(t)]?.lon;
      if (target == null) continue;
      final sep = angDist(moon, target);
      if (types.any((a) => (sep - a.angle).abs() <= orb)) return true;
    }
    return false;
  },
  'day_tension': (m, r) {
    final v = m.dayTension;
    if (v == null) return false;
    final min = r.params['min'] as num?, max = r.params['max'] as num?;
    return (min == null || v >= min) && (max == null || v <= max);
  },
};

/// Conditions the engine knows (validated against the rule file in tools/content).
Set<String> get electionConditions => electionPredicates.keys.toSet();

/// A run of adjacent samples with the same outcome.
class ElectionWindow {
  /// Julian Days UT, [start, end).
  final double start, end;
  final RuleOutcome outcome;

  /// Score band from the rule file, or `none` when below every band.
  final String verdict;

  /// False for the "least bad" window shown when nothing passed.
  final bool passed;
  const ElectionWindow(this.start, this.end, this.outcome, this.verdict, this.passed);

  int get score => outcome.score;
  List<Rule> get plus => outcome.plus;
  List<Rule> get minus => outcome.minus;
  double get hours => (end - start) * 24;

  /// Middle of the window: the moment whose chart the app opens.
  double get middle => (start + end) / 2;
  @override
  String toString() => 'window [$start … $end) $score $verdict ${outcome.signature}';
}

class ElectionResult {
  final ElectionQuery query;
  final double from, to;

  /// Up to [ElectionQuery.maxWindows] passing windows, best first; or a single
  /// least-bad window with `passed == false` when nothing passed.
  final List<ElectionWindow> windows;

  /// Every window of the period (excluded ones included), in time order — for tests and diagnostics.
  final List<ElectionWindow> all;
  final int samples;
  const ElectionResult(this.query, this.from, this.to, this.windows, this.all, this.samples);

  bool get anyPassed => windows.any((w) => w.passed);
}

/// Election search (plan 10.7, docs/scoring.md). Samples every 10 minutes:
/// planets come from interpolated tracks (Moon hourly, others every 12 h),
/// the axes and houses are computed for every sample, adjacent samples with
/// the same fired rules merge into one window. Pure and deterministic; the
/// app runs it in an isolate.
class ElectionSearch {
  ElectionSearch._();

  static const stepDays = 10 / 1440;

  static ElectionResult run(ElectionQuery q, RuleBook book) {
    final place = q.place;
    final days = q.days.clamp(1, ElectionQuery.maxDays);
    final from = localMidnight(q.year, q.month, q.day, place);
    final end = DateTime.utc(q.year, q.month, q.day + days);
    final to = localMidnight(end.year, end.month, end.day, place);
    final personal = q.natal != null;
    final rules = book.active(q.intent.id, personal: personal);

    final timeline = MoonAspectTimeline.build(from, to, traditionalOnly: q.traditionalOnly);
    final tracks = <Body, LongitudeTrack>{Body.moon: timeline.moon, ...timeline.planets};
    final bodies = tracks.keys.toList();

    // Eclipses: local date of greatest eclipse.
    final eclipseDates = [
      for (final l in Lunar.lunations(from - 3, to + 3, kinds: {LunationKind.newMoon, LunationKind.fullMoon}))
        if (l.eclipse != null) _dayNumber(localTime(l.eclipse!.jdMax, place)),
    ];

    final hours = planetaryHourSpans(from, to, place.lat, place.lon);
    var hi = 0;

    List<double>? tension;
    if (personal) tension = TransitEngine(q.natal!).tensionSeries(from + 0.5, days + 1);

    final system = q.houseSystem ?? defaultHouseSystem(place.lat).system;
    final n = ((to - from) / stepDays).round();
    final all = <ElectionWindow>[];
    String? runSig;
    double runStart = from;
    RuleOutcome? runOutcome;
    var runBlocked = true;

    void close(double at) {
      if (runSig != null && !runBlocked) {
        final o = runOutcome!;
        final v = book.verdictOf(o.score);
        all.add(ElectionWindow(runStart, at, o, v ?? 'none', v != null));
      }
    }

    for (var i = 0; i < n; i++) {
      final t = from + i * stepDays;
      final local = localTime(t, place);
      final blocked = (q.hours != null && !q.hours!.contains(local.hour)) || (q.weekdays != null && !q.weekdays!.contains(local.weekday));
      RuleOutcome? outcome;
      String sig;
      if (blocked) {
        sig = '#blocked';
      } else {
        final lon = {for (final b in bodies) b: tracks[b]!.at(t)};
        final jde = t + deltaTSeconds(decimalYearOfJd(t)) / 86400;
        final ramc = Ephemeris.apparentSiderealDeg(t) + place.lon;
        final eps = Ephemeris.trueObliquity(jde);
        var houses = housesFromRamc(system, ramc, place.lat, eps);
        if (!houses.defined) houses = housesFromRamc(HouseSystem.porphyry, ramc, place.lat, eps);
        while (hi < hours.length && hours[hi].end <= t) {
          hi++;
        }
        final hour = hi < hours.length && hours[hi].covers(t) ? hours[hi] : null;
        final dn = _dayNumber(local);
        int? ecl;
        for (final e in eclipseDates) {
          final d = (dn - e).abs();
          if (ecl == null || d < ecl) ecl = d;
        }
        final dayIndex = (t - from).floor();
        final m = ElectionMoment._(
          t,
          q.intent,
          lon,
          tracks,
          houses,
          timeline.nextAspect(t),
          timeline.voidOverlaps(t, t + stepDays),
          hour?.ruler,
          ecl,
          q.natal,
          tension == null ? null : tension[dayIndex.clamp(0, tension.length - 1)],
        );
        outcome = evaluateRules(rules, electionPredicates, m);
        sig = outcome.excluded ? '#excluded' : outcome.signature;
      }
      if (sig != runSig) {
        close(t);
        runSig = sig;
        runStart = t;
        runOutcome = outcome;
        runBlocked = blocked || (outcome?.excluded ?? true);
      }
    }
    close(to);

    final ranked = [...all]..sort((a, b) {
        final s = b.score.compareTo(a.score);
        if (s != 0) return s;
        final d = b.hours.compareTo(a.hours);
        return d != 0 ? d : a.start.compareTo(b.start);
      });
    final picked = <ElectionWindow>[];
    final perDay = <int, int>{};
    for (final w in ranked.where((w) => w.passed)) {
      if (picked.length >= q.maxWindows) break;
      final d = _dayNumber(localTime(w.start, place));
      if ((perDay[d] ?? 0) >= q.maxPerDay) continue;
      perDay[d] = (perDay[d] ?? 0) + 1;
      picked.add(w);
    }
    if (picked.isEmpty && ranked.isNotEmpty) picked.add(ranked.first);
    return ElectionResult(q, from, to, picked, all, n);
  }

  static int _dayNumber(DateTime d) => DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;
}

/// UT of local midnight that starts a civil date at [place] (its zone, or local mean time).
double localMidnight(int year, int month, int day, GeoLocation place) => resolveMoment(
      LocalMoment(year: year, month: month, day: day, hour: 0, minute: 0, zone: place.zone, basis: place.zone == null ? TimeBasis.lmt : TimeBasis.zone),
      place.lon,
    ).jdUt;

/// Wall-clock time at [place] for a UT instant (zone, or local mean time).
DateTime localTime(double jdUt, GeoLocation place) {
  if (place.zone != null) return utToZone(jdUt, place.zone!);
  final u = dateTimeUtcFromJd(jdUt + place.lon / 360);
  return DateTime(u.year, u.month, u.day, u.hour, u.minute, u.second);
}

/// Planetary hours over a whole period from one scan of sunrises and sunsets.
/// Same crossings and rules as [PlanetaryHours.day]: a day runs from a sunrise
/// over the following sunset to the next sunrise, its ruler is the weekday of
/// the sunrise's local mean date. Polar stretches yield no hours.
List<PlanetaryHour> planetaryHourSpans(double from, double to, double lat, double lon) {
  final c = SunRiseSet.crossings(from - 1.5, to + 1.5, lat, lon);
  final out = <PlanetaryHour>[];
  for (var k = 0; k + 2 < c.length; k++) {
    if (!c[k].rising || c[k + 1].rising || !c[k + 2].rising) continue;
    final r = c[k].jd, s = c[k + 1].jd, nx = c[k + 2].jd;
    if (nx - r > 1.25) continue;
    final date = calendarFromJd(r + lon / 360, calendar: CalendarKind.gregorian);
    final ruler = dayRulerOfWeekday(DateTime.utc(date.year, date.month, date.day.floor()).weekday);
    final first = chaldeanOrder.indexOf(ruler);
    final hd = (s - r) / 12, hn = (nx - s) / 12;
    for (var i = 0; i < 24; i++) {
      final start = i < 12 ? r + i * hd : s + (i - 12) * hn;
      final end = i < 11 ? r + (i + 1) * hd : (i == 11 ? s : (i < 23 ? s + (i - 11) * hn : nx));
      out.add(PlanetaryHour(chaldeanOrder[(first + i) % 7], i + 1, start, end));
    }
  }
  return out;
}
