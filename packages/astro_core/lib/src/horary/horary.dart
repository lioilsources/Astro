import 'dart:math' as math;

import '../angles.dart';
import '../aspects.dart';
import '../dignities.dart';
import '../ephemeris.dart';
import '../houses.dart';
import '../location.dart';
import '../model.dart';
import '../moon_aspects.dart';
import '../planetary_hours.dart';
import '../rules.dart';
import '../stars.dart';
import '../time.dart';
import '../track.dart';
import 'horary_book.dart';
import 'lilly_tables.dart';

/// Verdicts of the closed set (plan 10.8), content ids `horary/verdict/{id}`.
enum HoraryVerdict {
  yes('yes'),
  yesDifficult('yes_difficult'),
  no('no'),
  past('past'),
  nothing('nothing'),
  unclear('unclear');

  final String id;
  const HoraryVerdict(this.id);
}

/// What the app asks: a topic from the closed list, whom it is about, the
/// moment the question was confirmed and the place of residence.
class HoraryQuestion {
  final double jdUt;
  final GeoLocation place;
  final String topic;
  final String person;
  const HoraryQuestion({required this.jdUt, required this.place, required this.topic, this.person = 'self'});
}

/// One of the seven planets at the moment of the question.
class HoraryPlanet {
  final Body body;
  final double lon;
  final double lat;

  /// Degrees per day.
  final double speed;
  final int house;
  const HoraryPlanet(this.body, this.lon, this.lat, this.speed, this.house);

  Sign get sign => Sign.ofLongitude(lon);
  bool get retrograde => speed < 0;
  double get degreeInSign => norm360(lon) % 30;
}

/// The horary figure (plan 10.8): seven planets, traditional rulers,
/// Regiomontanus houses (Porphyry inside the polar circles).
class HoraryChart {
  final double jdUt;
  final GeoLocation place;
  final HouseResult houses;
  final Map<Body, HoraryPlanet> planets;

  /// Sun above the horizon: day chart (selects the triplicity ruler).
  final bool isDay;
  final Body? hourRuler;
  const HoraryChart(this.jdUt, this.place, this.houses, this.planets, this.isDay, this.hourRuler);

  static HoraryChart at(double jdUt, GeoLocation place) {
    final jde = jdUt + deltaTSeconds(decimalYearOfJd(jdUt)) / 86400;
    final eps = Ephemeris.trueObliquity(jde);
    final ramc = Ephemeris.apparentSiderealDeg(jdUt) + place.lon;
    final polar = place.lat.abs() >= 90 - eps;
    final houses = housesFromRamc(polar ? HouseSystem.porphyry : HouseSystem.regiomontanus, ramc, place.lat, eps);
    final planets = <Body, HoraryPlanet>{};
    for (final b in Body.traditional) {
      final p = Ephemeris.positionTT(b, jde);
      planets[b] = HoraryPlanet(b, p.lon, p.lat, p.speed, houses.houseOf(p.lon));
    }
    final isDay = norm360(planets[Body.sun]!.lon - houses.asc) >= 180;
    final hour = PlanetaryHours.hourAt(jdUt, place.lat, place.lon);
    return HoraryChart(jdUt, place, houses, planets, isDay, hour?.ruler);
  }

  double get asc => houses.asc;
  Sign get ascSign => Sign.ofLongitude(asc);
  HoraryPlanet operator [](Body b) => planets[b]!;

  /// Sign on the cusp of [house] and its traditional ruler.
  Sign cuspSign(int house) => Sign.ofLongitude(houses.cusps![house - 1]);
  Body rulerOf(int house) => traditionalRuler(cuspSign(house));
}

// ---------------------------------------------------------------------------
// Strength (step 1)

/// One fortitude or debility with Lilly's points (lilly_tables.dart).
class StrengthItem {
  final String id;
  final int points;
  final bool essential;
  const StrengthItem(this.id, this.points, {required this.essential});
  @override
  String toString() => '$id ${points > 0 ? '+' : ''}$points';
}

class Strength {
  final Body body;
  final List<StrengthItem> items;
  const Strength(this.body, this.items);

  int get essential => items.where((i) => i.essential).fold(0, (s, i) => s + i.points);
  int get accidental => items.where((i) => !i.essential).fold(0, (s, i) => s + i.points);
  int get total => essential + accidental;
  bool has(String id) => items.any((i) => i.id == id);
}

/// Essential dignities of [b] at [lon] (Lilly's table, CA p. 104; points p. 115).
List<StrengthItem> essentialDignities(Body b, double lon, {required bool isDay}) {
  final sign = Sign.ofLongitude(lon);
  final out = <StrengthItem>[];
  void add(String id) => out.add(StrengthItem(id, lillyFortitudes[id]!, essential: true));
  if (domicile[b]!.contains(sign)) add('domicile');
  if (exaltation[b] == sign) add('exaltation');
  if (triplicityRuler(sign, isDay: isDay) == b) add('triplicity');
  if (termRuler(lon) == b) add('term');
  if (faceRuler(lon) == b) add('face');
  if (domicile[b]!.any((d) => d.opposite == sign)) add('detriment');
  if (exaltation[b]?.opposite == sign) add('fall');
  // p. 112: peregrine "when he is in the degrees of any Signe wherein he hath no essentiall dignity".
  if (!out.any((i) => i.points > 0)) add('peregrine');
  return out;
}

/// Has any of the five essential dignities (p. 104) at [lon].
bool hasEssentialDignity(Body b, double lon, {required bool isDay}) =>
    essentialDignities(b, lon, isDay: isDay).any((i) => i.points > 0);

/// Mean daily motion test: faster than the mean = swift.
bool _swift(HoraryPlanet p) => p.speed.abs() > lillyMeanMotion[p.body]!;

/// p. 114, besieged: "placed betwixt the bodies of the two Malevolent Planets
/// ♄ and ♂" — the nearest planets on either side in the zodiac are Saturn and Mars.
bool besieged(Body b, Map<Body, HoraryPlanet> planets) {
  if (b == Body.saturn || b == Body.mars) return false;
  final lon = planets[b]!.lon;
  Body? ahead, behind;
  var da = 361.0, db = 361.0;
  for (final o in planets.values) {
    if (o.body == b) continue;
    final d = norm360(o.lon - lon);
    if (d > 0 && d < da) {
      da = d;
      ahead = o.body;
    }
    final e = norm360(lon - o.lon);
    if (e > 0 && e < db) {
      db = e;
      behind = o.body;
    }
  }
  return {ahead, behind}.containsAll({Body.saturn, Body.mars});
}

Strength strengthOf(Body b, HoraryChart c, {Map<FixedStar, double>? stars}) {
  final p = c[b];
  final items = [...essentialDignities(b, p.lon, isDay: c.isDay)];
  void add(String id, {bool essential = false}) => items.add(StrengthItem(id, lillyFortitudes[id]!, essential: essential));
  // p. 115: "or in mutual reception with another Planet by house" (5), "or reception by exaltation" (4).
  for (final o in Body.traditional) {
    if (o == b) continue;
    if (!items.any((i) => i.id == 'domicile' || i.id == 'mutual_reception_house') && mutualReceptionByHouse(b, o, c.planets)) {
      add('mutual_reception_house', essential: true);
    }
    if (!items.any((i) => i.id == 'exaltation' || i.id == 'mutual_reception_exaltation') && exaltation[b] == c[o].sign && exaltation[o] == p.sign) {
      add('mutual_reception_exaltation', essential: true);
    }
  }
  final h = p.house;
  switch (h) {
    case 1 || 10:
      add('house_1_10');
    case 4 || 7 || 11:
      add('house_4_7_11');
    case 2 || 5:
      add('house_2_5');
    case 9:
      add('house_9');
    case 3:
      add('house_3');
    case 12:
      add('house_12');
    case 6 || 8:
      add('house_6_8');
  }
  if (b != Body.sun && b != Body.moon) add(p.retrograde ? 'retrograde' : 'direct');
  add(_swift(p) ? 'swift' : 'slow');
  final sun = c[Body.sun];
  if (b == Body.moon) {
    // p. 114: occidental from the conjunction to the opposition = increasing.
    add(norm360(p.lon - sun.lon) < 180 ? 'moon_increasing' : 'moon_decreasing');
  } else if (b != Body.sun) {
    // p. 114: oriental from the conjunction to the opposition (superiors); in
    // fewer degrees than the Sun or the sign before (Mercury, Venus): both mean
    // the planet lies behind the Sun in the zodiac.
    final oriental = norm360(sun.lon - p.lon) < 180;
    final superior = b == Body.saturn || b == Body.jupiter || b == Body.mars;
    if (superior) add(oriental ? 'superior_oriental' : 'superior_occidental');
    if (b == Body.mercury || b == Body.venus) add(oriental ? 'inferior_oriental' : 'inferior_occidental');
  }
  if (b != Body.sun) {
    switch (solarCondition(p.lon, sun.lon)) {
      case SolarCondition.cazimi:
        add('cazimi');
      case SolarCondition.combust:
        add('combust');
      case SolarCondition.underBeams:
        add('under_beams');
      case SolarCondition.free:
        add('free_from_combustion');
    }
  }
  // Partile (same degree) aspects to the benefics and malefics.
  for (final o in c.planets.values) {
    if (o.body == b) continue;
    final t = partileAspect(p.lon, o.lon);
    if (t == null) continue;
    final benefic = o.body == Body.jupiter || o.body == Body.venus;
    final malefic = o.body == Body.saturn || o.body == Body.mars;
    if (benefic) {
      if (t == AspectType.conjunction) add('partile_conj_benefic');
      if (t == AspectType.trine) add('partile_trine_benefic');
      if (t == AspectType.sextile) add('partile_sextile_benefic');
    }
    if (malefic) {
      if (t == AspectType.conjunction) add('partile_conj_malefic');
      if (t == AspectType.opposition) add('partile_opposition_malefic');
      if (t == AspectType.square) add('partile_square_malefic');
    }
  }
  final node = Ephemeris.longitude(Body.meanNode, c.jdUt);
  if (partileAspect(p.lon, node) == AspectType.conjunction) add('partile_north_node');
  if (partileAspect(p.lon, node + 180) == AspectType.conjunction) add('partile_south_node');
  if (besieged(b, c.planets)) add('besieged');
  final s = stars ?? starLongitudes(c.jdUt + deltaTSeconds(decimalYearOfJd(c.jdUt)) / 86400);
  for (final MapEntry(key: star, value: l) in s.entries) {
    final st = lillyStars[star.id];
    if (st != null && angDist(p.lon, l) <= st.orb) add(st.id);
  }
  return Strength(b, items);
}

/// Partile aspect: both points in the same degree of their signs (Lilly's
/// usage), and the signs at the aspect's distance.
AspectType? partileAspect(double a, double b) {
  if ((norm360(a) % 30).floor() != (norm360(b) % 30).floor()) return null;
  final signs = (Sign.ofLongitude(a).index - Sign.ofLongitude(b).index).abs() % 12;
  final d = math.min(signs, 12 - signs);
  return switch (d) { 0 => AspectType.conjunction, 2 => AspectType.sextile, 3 => AspectType.square, 4 => AspectType.trine, 6 => AspectType.opposition, _ => null };
}

enum SolarCondition { cazimi, combust, underBeams, free }

/// CA p. 113: cazimi within 17′; combust within 8°30′ and in the same sign
/// ("Combustion can onely be by personall ☌ in one Signe", p. 114); under the
/// beams within 17°.
SolarCondition solarCondition(double lon, double sunLon) {
  final d = angDist(lon, sunLon);
  if (d <= lillyCazimi) return SolarCondition.cazimi;
  if (d <= lillyCombust && Sign.ofLongitude(lon) == Sign.ofLongitude(sunLon)) return SolarCondition.combust;
  if (d <= lillyUnderBeams) return SolarCondition.underBeams;
  return SolarCondition.free;
}

// ---------------------------------------------------------------------------
// Reception (step 5)

/// [host] receives [guest] by house or exaltation: the guest stands in a sign
/// the host rules or is exalted in. CA p. 112: reception "by Houses … is the
/// strongest and best"; p. 171: "single reception by exaltation without other
/// testimonies profiteth not" — the app counts house and exaltation only.
bool receives(Body host, Body guest, Map<Body, HoraryPlanet> planets) {
  final s = planets[guest]!.sign;
  return domicile[host]!.contains(s) || exaltation[host] == s;
}

bool mutualReception(Body a, Body b, Map<Body, HoraryPlanet> planets) => receives(a, b, planets) && receives(b, a, planets);

/// Mutual reception by house (p. 112: "☉ in ♈ and ♂ in ♌").
bool mutualReceptionByHouse(Body a, Body b, Map<Body, HoraryPlanet> planets) =>
    domicile[a]!.contains(planets[b]!.sign) && domicile[b]!.contains(planets[a]!.sign);

/// [host] receives [guest] in one of the listed essential dignities (p. 126:
/// translation "received either by House, Triplicity or Terme"; collection:
/// "they both receive him in some of their essentiall dignities").
bool receivesIn(Body host, Body guest, HoraryChart c, Set<String> dignities) =>
    essentialDignities(host, c[guest].lon, isDay: c.isDay).any((i) => dignities.contains(i.id));

// ---------------------------------------------------------------------------
// Motion: the sky stepped forward (step 2)

/// An exact major aspect between two planets in the future.
class Perfection {
  final Body a, b;
  final AspectType type;

  /// Julian Day UT of exactness.
  final double jd;

  /// Distance from exact at the question moment, degrees.
  final double degrees;
  const Perfection(this.a, this.b, this.type, this.jd, this.degrees);
  bool get hard => type == AspectType.square || type == AspectType.opposition;
  @override
  String toString() => '${a.name} ${type.name} ${b.name} at $jd (${degrees.toStringAsFixed(2)}°)';
}

/// Longitudes of the seven planets from the question moment forward
/// (Moon hourly, the others every 12 h to 2 days, Lagrange-interpolated).
/// Tests build skies with constructed motions via [HorarySky.custom].
class HorarySky {
  final double jd;
  final double horizonDays;
  final double Function(Body b, double t) _lon;
  final double Function(Body b) _end;
  HorarySky.custom(this.jd, this._lon, {this.horizonDays = 400, double Function(Body b)? end})
      : _end = end ?? ((b) => jd + horizonDays);

  /// Moon samples for this many days at most: beyond, the Moon has left its sign.
  static const moonDays = 30.0;
  static const scanStep = 1 / 24;

  /// Sample step per body, days (cubic interpolation keeps these well under 1′).
  static const _step = {
    Body.moon: 1 / 24,
    Body.mercury: 0.5,
    Body.venus: 0.5,
    Body.sun: 1.0,
    Body.mars: 1.0,
    Body.jupiter: 2.0,
    Body.saturn: 2.0,
  };

  factory HorarySky.build(double jd, {double horizonDays = 400}) {
    final tracks = {
      for (final b in Body.traditional) b: LongitudeTrack.build(b, jd - 3, jd + (b == Body.moon ? moonDays : horizonDays), _step[b]!),
    };
    return HorarySky.custom(jd, (b, t) => tracks[b]!.at(t),
        horizonDays: horizonDays, end: (b) => jd + (b == Body.moon ? moonDays : horizonDays));
  }

  /// Planets moving uniformly from [start] (longitude, degrees per day) —
  /// constructed cases for tests.
  factory HorarySky.linear(double jd, Map<Body, ({double lon, double speed})> start, {double horizonDays = 400}) =>
      HorarySky.custom(jd, (b, t) => norm360(start[b]!.lon + start[b]!.speed * (t - jd)), horizonDays: horizonDays);

  double lon(Body b, double t) => _lon(b, t);
  double speed(Body b, double t) => angDiff(_lon(b, t + 0.01), _lon(b, t - 0.01)) / 0.02;
  double end(Body b) => _end(b);

  final Map<Body, double> _exit = {};

  /// When [b] leaves its present sign (by direct or retrograde motion); the
  /// end of the horizon when it does not.
  double signExit(Body b) => _exit.putIfAbsent(b, () {
        final s0 = lon(b, jd) ~/ 30;
        var t = jd;
        final e = end(b);
        while (t < e) {
          final t2 = math.min(t + scanStep, e);
          if (lon(b, t2) ~/ 30 != s0) {
            var lo = t, hi = t2;
            for (var i = 0; i < 20; i++) {
              final m = (lo + hi) / 2;
              if (lon(b, m) ~/ 30 == s0) {
                lo = m;
              } else {
                hi = m;
              }
            }
            return (lo + hi) / 2;
          }
          t = t2;
        }
        return e;
      });

  /// First moment in (from, until) when [b] changes direction, or null.
  double? station(Body b, double from, double until) {
    if (b == Body.sun || b == Body.moon) return null;
    var t = from;
    var s0 = speed(b, t);
    final step = 0.25;
    while (t < until) {
      final t2 = math.min(t + step, until);
      final s2 = speed(b, t2);
      if ((s0 < 0) != (s2 < 0)) {
        var lo = t, hi = t2;
        for (var i = 0; i < 20; i++) {
          final m = (lo + hi) / 2;
          if ((speed(b, m) < 0) == (s0 < 0)) {
            lo = m;
          } else {
            hi = m;
          }
        }
        return (lo + hi) / 2;
      }
      t = t2;
      s0 = s2;
    }
    return null;
  }

  /// The first exact major aspect between [a] and [b] after the question and
  /// before [until] (default: before either leaves its sign). Hourly steps,
  /// bisection to about a second.
  Perfection? perfection(Body a, Body b, {double? until}) {
    final stop = math.min(until ?? math.min(signExit(a), signExit(b)), math.min(end(a), end(b)));
    Perfection? best;
    for (final type in AspectType.major) {
      for (final side in (type == AspectType.conjunction || type == AspectType.opposition) ? const [1] : const [1, -1]) {
        double f(double t) => angDiff(angDiff(lon(a, t), lon(b, t)), side * type.angle);
        var t = jd;
        var f0 = f(t);
        final degrees = f0.abs();
        while (t < stop && (best == null || t < best.jd)) {
          final t2 = math.min(t + scanStep, stop);
          final f2 = f(t2);
          if (f0.abs() < 90 && f2.abs() < 90 && (f0 < 0) != (f2 < 0)) {
            var lo = t, hi = t2;
            for (var i = 0; i < 16; i++) {
              final m = (lo + hi) / 2;
              if ((f(m) < 0) == (f0 < 0)) {
                lo = m;
              } else {
                hi = m;
              }
            }
            final jx = (lo + hi) / 2;
            if (jx > jd && (best == null || jx < best.jd)) best = Perfection(a, b, type, jx, degrees);
            break;
          }
          t = t2;
          f0 = f2;
        }
      }
    }
    return best;
  }

  /// Aspect within the planets' moieties at the question moment, with
  /// applying (getting closer) or separating.
  ({AspectType type, double orb, bool applying})? aspectNow(Body a, Body b) => matchAspect(
        lon(a, jd),
        speed(a, jd),
        lon(b, jd),
        speed(b, jd),
        (_) => lillyMoiety(a) + lillyMoiety(b),
      );
}

// ---------------------------------------------------------------------------
// Judgement

/// How the significators come together (steps 2 and 3).
/// How the significators come together (steps 2 and 3).
enum PerfectionRoute { direct, moon, translation, collection }

/// What cancels a perfection (step 4).
enum Cancellation { prohibition, frustration, refranation, combustion }

/// Everything the tree found; the testimonies of the rule file read it.
class HoraryFacts {
  final HoraryChart chart;
  final HoraryTopic topic;
  final HoraryPerson person;

  /// House of the matter (derived when [person] is not the querent).
  final int quesitedHouse;

  /// Querent (or the person asked about): ruler of the ASC (of the person's house).
  final Body querent;

  /// Moon as co-significator of the querent (questions about oneself; CA p. 124).
  final Body? coQuerent;
  final Body quesited;
  final Body? natural;
  final Map<Body, Strength> strength;
  final Perfection? perfection;
  final PerfectionRoute? route;

  /// Translating or collecting planet.
  final Body? mediator;
  final Cancellation? cancellation;

  /// Third planet of a prohibition or frustration.
  final Body? obstacle;

  /// Significators separating from an aspect within orbs (matter is past).
  final ({AspectType type, double orb, bool applying})? separating;

  /// Reception by house or exaltation between the perfecting pair, and mutual.
  final bool reception;
  final bool mutual;

  /// Mutual reception by house between the perfecting pair (opposition rule, p. 125).
  final bool mutualByHouse;

  /// Both of the perfecting pair have an essential dignity (square rule, p. 125).
  final bool bothDignified;

  /// Natural significator perfects an aspect with the querent's significator.
  final Perfection? naturalPerfection;
  final bool moonVoid;
  const HoraryFacts({
    required this.chart,
    required this.topic,
    required this.person,
    required this.quesitedHouse,
    required this.querent,
    required this.coQuerent,
    required this.quesited,
    required this.natural,
    required this.strength,
    required this.perfection,
    required this.route,
    required this.mediator,
    required this.cancellation,
    required this.obstacle,
    required this.separating,
    required this.reception,
    required this.mutual,
    required this.mutualByHouse,
    required this.bothDignified,
    required this.naturalPerfection,
    required this.moonVoid,
  });

  /// The square or opposition does not perfect the matter by Lilly's rule
  /// (p. 125): a square needs dignity in both, an opposition mutual reception by house.
  bool get hardBlocked {
    final p = perfection;
    if (p == null) return false;
    if (p.type == AspectType.square) return !bothDignified;
    if (p.type == AspectType.opposition) return !mutualByHouse;
    return false;
  }
}

/// Timing estimate: degrees to perfection in Lilly's unit (CA pp. 171–172).
class HoraryTiming {
  final double degrees;

  /// `days`, `weeks`, `months`, … (content `horary/timing/{unit}`).
  final String unit;

  /// Houses of the two significators.
  final int houseA, houseB;
  const HoraryTiming(this.degrees, this.unit, this.houseA, this.houseB);

  /// Whole units, at least one.
  int get count => math.max(1, degrees.round());
}

/// Lost object: quarter of heaven by sign and by house of its significator.
class HoraryLost {
  final Body significator;
  final Sign sign;
  final int house;
  final String bySign;
  final String byHouse;
  const HoraryLost(this.significator, this.sign, this.house, this.bySign, this.byHouse);
}

class HoraryJudgement {
  final HoraryQuestion question;
  final HoraryChart chart;
  final HoraryFacts? facts;

  /// Null for health, death and pregnancy (owner decision 20).
  final HoraryVerdict? verdict;
  final List<Rule> considerations;
  final List<Rule> plus;
  final List<Rule> minus;
  final HoraryTiming? timing;
  final HoraryLost? lost;
  const HoraryJudgement(this.question, this.chart, this.facts, this.verdict, this.considerations, this.plus, this.minus, this.timing, this.lost);

  bool get noVerdict => verdict == null;
}

/// Context of the consideration and testimony predicates.
class HoraryContext {
  final HoraryChart chart;
  final HorarySky sky;
  final HoraryFacts? facts;
  final MoonAspectTimeline moonTimeline;
  const HoraryContext(this.chart, this.sky, this.facts, this.moonTimeline);
}

/// Predicates of the conditions used in `content/rules/horary.json`
/// (docs/horary.md lists them with their sources).
final Map<String, RulePredicate<HoraryContext>> horaryPredicates = {
  // Considerations before judgement.
  'asc_degree_below': (c, r) => norm360(c.chart.asc) % 30 < r.number('deg', 3),
  'asc_degree_above': (c, r) => norm360(c.chart.asc) % 30 >= r.number('deg', 27),
  'moon_void': (c, r) => c.facts?.moonVoid ?? c.moonTimeline.voidAt(c.chart.jdUt) != null,
  'moon_between': (c, r) {
    final l = c.chart[Body.moon].lon;
    return l >= r.number('from', 195) && l < r.number('to', 225);
  },
  'body_in_house': (c, r) => r.ints('houses').contains(c.chart[Body.values.byName(r.params['body'] as String)].house),
  'hour_ruler_disagrees': (c, r) {
    final h = c.chart.hourRuler;
    if (h == null) return false;
    return !hourAgreesWithAsc(h, traditionalRuler(c.chart.ascSign));
  },
  // Testimonies.
  'perfection': (c, r) {
    final f = c.facts;
    final p = f?.perfection;
    if (f == null || p == null || f.cancellation != null) return false;
    final route = r.params['route'] as String?;
    if (route != null && f.route?.name != route) return false;
    final aspects = r.strings('aspects');
    return aspects.isEmpty || aspects.contains(p.type.name);
  },
  // Light translated: as the route, or by a third planet alongside a direct perfection.
  'translated': (c, r) {
    final f = c.facts;
    if (f == null || f.mediator == null || f.cancellation != null || f.hardBlocked) return false;
    return f.route == PerfectionRoute.translation || f.route == PerfectionRoute.direct || f.route == PerfectionRoute.moon;
  },
  'cancelled': (c, r) => c.facts?.cancellation?.name == r.params['by'],
  'separating': (c, r) => c.facts?.separating != null && c.facts?.perfection == null && c.facts?.cancellation == null,
  'no_aspect': (c, r) => c.facts != null && c.facts!.perfection == null && c.facts!.separating == null && c.facts!.cancellation == null,
  'reception': (c, r) {
    final f = c.facts;
    if (f == null || f.perfection == null) return false;
    return (r.params['mutual'] == true) ? f.mutual : (f.reception && !f.mutual);
  },
  'hard_blocked': (c, r) {
    final f = c.facts;
    return f != null && f.cancellation == null && f.hardBlocked;
  },
  'significator_strength': (c, r) {
    final f = c.facts;
    if (f == null) return false;
    final who = r.params['who'] == 'quesited' ? f.quesited : f.querent;
    final s = f.strength[who]!.total;
    final min = r.params['min'] as num?, max = r.params['max'] as num?;
    return (min == null || s >= min) && (max == null || s <= max);
  },
  'significator_state': (c, r) {
    final f = c.facts;
    if (f == null) return false;
    final who = r.params['who'] == 'quesited' ? f.quesited : f.querent;
    return f.strength[who]!.has(r.params['state'] as String);
  },
  'significator_in_house': (c, r) {
    final f = c.facts;
    if (f == null || f.querent == f.quesited) return false;
    // The quesited's significator in the querent's house, or the querent's in the quesited's.
    final quesitedInFirst = r.params['who'] == 'quesited';
    final b = quesitedInFirst ? f.quesited : f.querent;
    final target = quesitedInFirst ? f.person.house : f.quesitedHouse;
    return c.chart[b].house == target;
  },
  'natural_perfection': (c, r) => c.facts?.naturalPerfection != null,
};

Set<String> get horaryConditions => horaryPredicates.keys.toSet();

/// Horary judgement by Lilly's rules (plan 10.8, docs/horary.md). Pure and
/// deterministic: the same moment, place, topic and person always give the
/// same result. The app runs it in an isolate.
class HoraryEngine {
  HoraryEngine._();

  static HoraryJudgement judge(HoraryQuestion q, HoraryBook book) {
    final chart = HoraryChart.at(q.jdUt, q.place);
    final topic = book.topic(q.topic);
    final person = book.person(q.person);
    final timeline = MoonAspectTimeline.build(q.jdUt - 0.5, q.jdUt + 0.5, traditionalOnly: true);
    final pre = HoraryContext(chart, HorarySky.custom(q.jdUt, (b, t) => chart[b].lon), null, timeline);
    final considerations = evaluateRules(book.considerations, horaryPredicates, pre).fired;
    if (topic.noVerdict) {
      return HoraryJudgement(q, chart, null, null, considerations, const [], const [], null, null);
    }
    final sky = HorarySky.build(q.jdUt);
    final facts = HoraryEngine.facts(chart, sky, topic, person, book, moonVoid: timeline.voidAt(chart.jdUt) != null);
    final ctx = HoraryContext(chart, sky, facts, timeline);
    final testimonies = evaluateRules(book.testimonies, horaryPredicates, ctx);
    final verdict = _verdict(facts);
    HoraryTiming? timing;
    final p = facts.perfection;
    if (p != null && (verdict == HoraryVerdict.yes || verdict == HoraryVerdict.yesDifficult)) {
      final ha = chart[p.a].house, hb = chart[p.b].house;
      timing = HoraryTiming(p.degrees, book.timeUnit(HouseKind.of(ha), HouseKind.of(hb)), ha, hb);
    }
    HoraryLost? lost;
    if (topic.lost) {
      final s = chart[facts.quesited];
      lost = HoraryLost(facts.quesited, s.sign, s.house, book.lostBySign[s.sign.name]!, book.lostByHouse['${s.house}']!);
    }
    final plus = [...testimonies.plus]..sort((a, b) => b.weight.compareTo(a.weight));
    final minus = [...testimonies.minus]..sort((a, b) => b.weight.compareTo(a.weight));
    return HoraryJudgement(q, chart, facts, verdict, considerations, plus, minus, timing, lost);
  }

  /// Verdict from the facts (the tree of plan 10.8, docs/horary.md).
  static HoraryVerdict verdictOf(HoraryFacts f) => _verdict(f);

  static HoraryVerdict _verdict(HoraryFacts f) {
    if (f.querent == f.quesited && f.coQuerent == null) return HoraryVerdict.unclear;
    if (f.cancellation != null) return HoraryVerdict.nothing;
    final p = f.perfection;
    if (p != null) {
      if (f.hardBlocked) return HoraryVerdict.no;
      if (p.type == AspectType.opposition) return HoraryVerdict.yesDifficult;
      if (p.type == AspectType.square) return f.reception ? HoraryVerdict.yes : HoraryVerdict.yesDifficult;
      return HoraryVerdict.yes;
    }
    if (f.separating != null) return HoraryVerdict.past;
    return HoraryVerdict.no;
  }

  /// Dignities in which a translator must be received (CA p. 126).
  static const _translationReception = {'domicile', 'triplicity', 'term'};

  /// Any essential dignity (collection, CA p. 126).
  static const _anyDignity = {'domicile', 'exaltation', 'triplicity', 'term', 'face'};

  /// Steps 1–5 of the tree on [chart] and the moving [sky] (public for
  /// constructed test cases).
  static HoraryFacts facts(HoraryChart chart, HorarySky sky, HoraryTopic topic, HoraryPerson person, HoraryBook book, {bool moonVoid = false}) {
    final quesitedHouse = derivedHouse(person.house, topic.house);
    final querent = chart.rulerOf(person.house);
    final coQuerent = person.isSelf ? Body.moon : null;
    final quesited = chart.rulerOf(quesitedHouse);
    final natural = topic.natural;
    final stars = starLongitudes(chart.jdUt + deltaTSeconds(decimalYearOfJd(chart.jdUt)) / 86400);
    final strength = {for (final b in Body.traditional) b: strengthOf(b, chart, stars: stars)};

    HoraryFacts result({
      Perfection? perfection,
      PerfectionRoute? route,
      Body? mediator,
      Cancellation? cancellation,
      Body? obstacle,
      ({AspectType type, double orb, bool applying})? separating,
      Body? a,
      Body? b,
      Perfection? naturalPerfection,
    }) {
      final pa = perfection?.a ?? a ?? querent, pb = perfection?.b ?? b ?? quesited;
      return HoraryFacts(
        chart: chart,
        topic: topic,
        person: person,
        quesitedHouse: quesitedHouse,
        querent: querent,
        coQuerent: coQuerent,
        quesited: quesited,
        natural: natural,
        strength: strength,
        perfection: perfection,
        route: route,
        mediator: mediator,
        cancellation: cancellation,
        obstacle: obstacle,
        separating: separating,
        reception: pa != pb && (receives(pa, pb, chart.planets) || receives(pb, pa, chart.planets)),
        mutual: pa != pb && mutualReception(pa, pb, chart.planets),
        mutualByHouse: pa != pb && mutualReceptionByHouse(pa, pb, chart.planets),
        bothDignified: hasEssentialDignity(pa, chart[pa].lon, isDay: chart.isDay) && hasEssentialDignity(pb, chart[pb].lon, isDay: chart.isDay),
        naturalPerfection: naturalPerfection,
        moonVoid: moonVoid,
      );
    }

    // When both are signified by one planet, the Moon stands for the querent.
    var a = querent;
    if (a == quesited) {
      if (coQuerent == null || coQuerent == quesited) return result();
      a = coQuerent;
    }
    final b = quesited;
    final sigs = {a, b, ?coQuerent};
    final now = sky.jd;
    double speedOf(Body x) => sky.speed(x, now).abs();

    Perfection? perfection;
    PerfectionRoute? route;
    Body? mediator;
    // 1. Direct perfection, then the Moon as co-significator (CA p. 124).
    perfection = sky.perfection(a, b);
    if (perfection != null) route = PerfectionRoute.direct;
    if (perfection == null && coQuerent != null && coQuerent != b && coQuerent != a) {
      perfection = sky.perfection(coQuerent, b);
      if (perfection != null) route = PerfectionRoute.moon;
    }
    // 2. Translation (CA p. 126): a lighter planet separates from one
    //    significator, who receives it by house, triplicity or term, and
    //    applies to the other before it meets any other planet.
    if (perfection == null) {
      outer:
      for (final l in Body.traditional) {
        if (sigs.contains(l) || speedOf(l) <= speedOf(a) || speedOf(l) <= speedOf(b)) continue;
        for (final (from, to) in [(a, b), (b, a)]) {
          final sep = sky.aspectNow(l, from);
          if (sep == null || sep.applying) continue;
          if (book.setting('translationNeedsReception', true) && !receivesIn(from, l, chart, _translationReception)) continue;
          final p = sky.perfection(l, to);
          if (p == null) continue;
          // "before he meeteth with the ☌ or aspect of any other Planet": the
          // translator applying to a slower planet first (faster ones run to it).
          final earlier = [
            for (final o in Body.traditional)
              if (o != l && o != to && o != from && speedOf(o) < speedOf(l)) sky.perfection(l, o, until: p.jd),
          ].nonNulls;
          if (earlier.isNotEmpty) continue;
          perfection = Perfection(a, b, p.type, p.jd, p.degrees);
          route = PerfectionRoute.translation;
          mediator = l;
          break outer;
        }
      }
    }
    // 3. Collection (CA p. 126): both apply to a heavier planet that stands in
    //    essential dignities of both.
    if (perfection == null && sky.aspectNow(a, b) == null) {
      for (final cb in Body.traditional) {
        if (sigs.contains(cb) || speedOf(cb) >= speedOf(a) || speedOf(cb) >= speedOf(b)) continue;
        final na = sky.aspectNow(a, cb), nb = sky.aspectNow(b, cb);
        if (na == null || nb == null || !na.applying || !nb.applying) continue;
        final pa = sky.perfection(a, cb), pb = sky.perfection(b, cb);
        if (pa == null || pb == null) continue;
        if (book.setting('collectionNeedsReception', true) &&
            !(receivesIn(a, cb, chart, _anyDignity) && receivesIn(b, cb, chart, _anyDignity))) {
          continue;
        }
        final later = pa.jd > pb.jd ? pa : pb;
        perfection = Perfection(a, b, later.type, later.jd, later.degrees);
        route = PerfectionRoute.collection;
        mediator = cb;
        break;
      }
    }

    // 4. What cancels the perfection (CA pp. 110–113).
    Cancellation? cancellation;
    Body? obstacle;
    if (perfection != null && (route == PerfectionRoute.direct || route == PerfectionRoute.moon)) {
      final pa = perfection.a, pb = perfection.b;
      final faster = speedOf(pa) >= speedOf(pb) ? pa : pb;
      final slower = faster == pa ? pb : pa;
      final needOrb = book.setting('obstacleWithinOrb', true);
      double? first;
      for (final o in Body.traditional) {
        if (sigs.contains(o) || o == pa || o == pb) continue;
        for (final target in [slower, faster]) {
          if (needOrb) {
            final n = sky.aspectNow(o, target);
            if (n == null || !n.applying) continue;
          }
          final p = sky.perfection(o, target, until: perfection.jd);
          if (p == null || (first != null && p.jd >= first)) continue;
          // A planet that joins one significator and then carries on to the
          // other translates the light instead of prohibiting (Lilly's own
          // judgement of CA pp. 387–388: ♃ "receiving his vertue which ♄ did
          // render unto him … transferred to the ☉").
          // Only a planet between the two in speed carries: one faster than
          // the applier prohibits (p. 111: the ☉ "first impediting ♂ and then ♄").
          final between = speedOf(o) < speedOf(faster) && speedOf(o) > speedOf(slower);
          final carry = between && target == slower ? sky.perfection(o, faster) : null;
          if (carry != null && carry.jd > p.jd) {
            mediator ??= o;
            continue;
          }
          first = p.jd;
          obstacle = o;
          // p. 112: frustration — the weightier significator is joined to another first.
          cancellation = target == slower && speedOf(target) > speedOf(o) ? Cancellation.frustration : Cancellation.prohibition;
        }
      }
    }
    // A third planet that has just separated from one significator and comes
    // to the other supports a direct perfection as translation (p. 111; the
    // ♃ of CA pp. 387–388).
    if (perfection != null && cancellation == null && mediator == null && (route == PerfectionRoute.direct || route == PerfectionRoute.moon)) {
      final pa = perfection.a, pb = perfection.b;
      search:
      for (final o in Body.traditional) {
        if (sigs.contains(o) || o == pa || o == pb) continue;
        for (final (x, y) in [(pa, pb), (pb, pa)]) {
          final sep = sky.aspectNow(o, x);
          if (sep == null || sep.applying) continue;
          if (sky.perfection(o, y) != null) {
            mediator = o;
            break search;
          }
        }
      }
    }
    // Refranation (p. 111): applying now, but one turns before the aspect is exact.
    if (perfection == null) {
      final n = sky.aspectNow(a, b);
      final until = math.min(sky.signExit(a), sky.signExit(b));
      if (n != null && n.applying && (sky.station(a, now, until) != null || sky.station(b, now, until) != null)) {
        cancellation = Cancellation.refranation;
      }
    }
    // Combustion (p. 123: "If the Lord of the Ascendant be Combust, neither question propounded will take").
    if (cancellation == null && perfection != null) {
      for (final s in {perfection.a, perfection.b}) {
        if (s == Body.sun) continue;
        if (solarCondition(chart[s].lon, chart[Body.sun].lon) == SolarCondition.combust) {
          cancellation = Cancellation.combustion;
          obstacle = Body.sun;
        }
      }
    }
    final sep = perfection == null && cancellation == null ? sky.aspectNow(a, b) : null;
    Perfection? naturalPerfection;
    if (natural != null && natural != a && natural != b) naturalPerfection = sky.perfection(a, natural);
    return result(
      perfection: perfection,
      route: route,
      mediator: mediator,
      cancellation: cancellation,
      obstacle: obstacle,
      separating: sep != null && !sep.applying ? sep : null,
      a: a,
      b: b,
      naturalPerfection: naturalPerfection,
    );
  }
}
