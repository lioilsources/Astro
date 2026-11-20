import 'dart:math' as math;

import 'angles.dart';
import 'aspects.dart';
import 'chart.dart';
import 'ephemeris.dart';
import 'houses.dart';
import 'location.dart';
import 'model.dart';
import 'moon.dart';
import 'time.dart';

/// Mean tropical year in days: in secondary progressions one day after birth
/// stands for one year of life (plan 10.5, docs/scoring.md).
const tropicalYearDays = 365.242189;

/// Orb of progressed aspects to natal points.
const progressedOrb = 1.0;

/// Progressed bodies that move enough in a lifetime to form new aspects.
/// Jupiter–Pluto move a few degrees at most; their natal aspects simply persist.
const progressedMovers = [Body.sun, Body.moon, Body.mercury, Body.venus, Body.mars];

/// Orb of a planet on a solar-return angle (conjunction with ASC, DSC, MC or IC).
const solarReturnAngleOrb = 5.0;

/// Progressed moment (Julian Day UT) standing for the life moment [lifeJd].
double progressedJdOf(Chart natal, double lifeJd) =>
    natal.time.jdUt + (lifeJd - natal.time.jdUt) / tropicalYearDays;

/// Life moment (Julian Day UT) of the progressed moment [progressedJd].
double lifeJdOf(Chart natal, double progressedJd) =>
    natal.time.jdUt + (progressedJd - natal.time.jdUt) * tropicalYearDays;

/// A progressed planet within 1° of a major aspect to a natal point.
class ProgressedAspect {
  final Body progressed;
  final ChartPoint natal;
  final AspectType type;

  /// Unsigned deviation from the exact angle, degrees.
  final double orb;
  final bool applying;
  const ProgressedAspect(this.progressed, this.natal, this.type, this.orb, this.applying);
  @override
  String toString() => 'p.${progressed.name} ${type.name} n.${natal.id} ${orb.toStringAsFixed(2)}${applying ? ' a' : ' s'}';
}

/// Secondary progressions of a natal chart for one moment of life.
///
/// Planets: positions at birth + N days for age N years. Angles: natal MC moved
/// by the solar arc (progressed − natal Sun), ASC derived from that MC at the
/// birth latitude. Houses of progressed planets are the natal houses.
class Progression {
  final Chart natal;

  /// Moment of life the progression is read for, Julian Day UT.
  final double lifeJd;

  /// Progressed moment, Julian Day UT.
  final double jdUt;
  final Map<Body, EclipticPosition> positions;

  /// Progressed Sun − natal Sun, degrees.
  final double solarArc;

  /// Progressed angles and house cusps; null without birth time.
  final HouseResult? houses;

  Progression._(this.natal, this.lifeJd, this.jdUt, this.positions, this.solarArc, this.houses);

  factory Progression.at(Chart natal, double lifeJd) {
    final jd = progressedJdOf(natal, lifeJd);
    final jde = jd + deltaTSeconds(decimalYearOfJd(jd)) / 86400;
    final pos = <Body, EclipticPosition>{
      for (final b in Body.planets)
        if (Ephemeris.available(b, jde)) b: Ephemeris.positionTT(b, jde),
    };
    final arc = angDiff(pos[Body.sun]!.lon, natal.positions[Body.sun]!.lon);
    final nh = natal.houses;
    HouseResult? houses;
    if (nh != null) {
      final mc = norm360(nh.mc + arc);
      final eps = Ephemeris.trueObliquity(jde);
      final ramc = norm360(math.atan2(math.sin(mc * deg) * math.cos(eps * deg), math.cos(mc * deg)) / deg);
      houses = housesFromRamc(nh.system, ramc, natal.birth.lat, eps);
    }
    return Progression._(natal, lifeJd, jd, pos, arc, houses);
  }

  /// Age in years at [lifeJd].
  double get ageYears => (lifeJd - natal.time.jdUt) / tropicalYearDays;

  EclipticPosition get moon => positions[Body.moon]!;
  EclipticPosition get sun => positions[Body.sun]!;
  double? get asc => houses?.asc;
  double? get mc => houses?.mc;

  /// Natal house of the progressed Moon; null without birth time.
  int? get moonHouse => natalHouseOf(natal, moon.lon);

  /// Progressed lunar phase (one cycle ≈ 29.5 years).
  MoonPhase get lunarPhase => MoonPhase.ofElongation(moon.lon - sun.lon);

  /// Aspects of the progressed movers to natal planets, ASC and MC, orb 1°.
  /// A mover to its own natal place counts only for the Moon (progressed lunar return).
  List<ProgressedAspect> get aspects {
    final out = <ProgressedAspect>[];
    final targets = <ChartPoint, double>{
      for (final b in Body.planets)
        if (natal.positions[b] != null) ChartPoint.body(b): natal.positions[b]!.lon,
      if (natal.houses != null) const ChartPoint.angle(Angle.asc): natal.houses!.asc,
      if (natal.houses != null) const ChartPoint.angle(Angle.mc): natal.houses!.mc,
    };
    for (final m in progressedMovers) {
      final p = positions[m];
      if (p == null) continue;
      for (final t in targets.entries) {
        if (t.key.body == m && m != Body.moon) continue;
        for (final type in AspectType.major) {
          final orb = (angDist(p.lon, t.value) - type.angle).abs();
          if (orb > progressedOrb) continue;
          // One progressed day later: is the orb shrinking?
          final next = (angDist(p.lon + p.speed * 0.01, t.value) - type.angle).abs();
          out.add(ProgressedAspect(m, t.key, type, orb, next < orb));
        }
      }
    }
    out.sort((a, b) => a.orb.compareTo(b.orb));
    return out;
  }
}

/// House 1..12 of [lon] in the natal chart; null without birth time.
int? natalHouseOf(Chart natal, double lon) {
  final h = natal.houses;
  if (h == null || !h.defined) return null;
  return h.houseOf(lon);
}

enum MilestoneKind { moonSign, moonHouse, sunSign, lunarPhase, solarReturn }

/// A point on the life timeline (plan 10.5).
class LifeMilestone {
  final MilestoneKind kind;

  /// Moment of life, Julian Day UT.
  final double jdUt;
  final Sign? sign;
  final int? house;
  final MoonPhase? phase;
  const LifeMilestone(this.kind, this.jdUt, {this.sign, this.house, this.phase});
  @override
  String toString() => '${kind.name} $jdUt ${sign?.name ?? house ?? phase?.id ?? ''}';
}

/// Sign and house changes of the progressed Moon, sign changes of the progressed
/// Sun and progressed lunar phase changes from birth to [years] of age, in time order.
List<LifeMilestone> progressedMilestones(Chart natal, {double years = 100}) {
  final t0 = natal.time.jdUt;
  final t1 = t0 + years;
  const step = 0.1; // progressed days; the Moon moves under 1.6° per step
  double lon(Body b, double t) => Ephemeris.longitude(b, t);
  final out = <LifeMilestone>[];

  // Finds the progressed moment in (a, b] where index(t) changes, by bisection.
  double bisect(int Function(double) index, double a, double b) {
    final ia = index(a);
    for (var i = 0; i < 40 && b - a > 1e-6; i++) {
      final m = (a + b) / 2;
      if (index(m) == ia) {
        a = m;
      } else {
        b = m;
      }
    }
    return b;
  }

  final cusps = natal.houses?.defined ?? false ? natal.houses : null;
  int moonSign(double t) => norm360(lon(Body.moon, t)) ~/ 30;
  int sunSign(double t) => norm360(lon(Body.sun, t)) ~/ 30;
  int moonHouse(double t) => cusps!.houseOf(lon(Body.moon, t));
  int phase(double t) => norm360(lon(Body.moon, t) - lon(Body.sun, t)) ~/ 45;

  var prev = (ms: moonSign(t0), ss: sunSign(t0), mh: cusps == null ? 0 : moonHouse(t0), ph: phase(t0));
  for (var a = t0; a < t1; a += step) {
    final b = math.min(a + step, t1);
    final cur = (ms: moonSign(b), ss: sunSign(b), mh: cusps == null ? 0 : moonHouse(b), ph: phase(b));
    if (cur.ms != prev.ms) {
      final t = bisect(moonSign, a, b);
      out.add(LifeMilestone(MilestoneKind.moonSign, lifeJdOf(natal, t), sign: Sign.values[moonSign(t)]));
    }
    if (cur.ss != prev.ss) {
      final t = bisect(sunSign, a, b);
      out.add(LifeMilestone(MilestoneKind.sunSign, lifeJdOf(natal, t), sign: Sign.values[sunSign(t)]));
    }
    if (cusps != null && cur.mh != prev.mh) {
      final t = bisect(moonHouse, a, b);
      out.add(LifeMilestone(MilestoneKind.moonHouse, lifeJdOf(natal, t), house: moonHouse(t)));
    }
    if (cur.ph != prev.ph) {
      final t = bisect(phase, a, b);
      out.add(LifeMilestone(MilestoneKind.lunarPhase, lifeJdOf(natal, t), phase: MoonPhase.values[phase(t)]));
    }
    prev = cur;
  }
  out.sort((a, b) => a.jdUt.compareTo(b.jdUt));
  return out;
}

/// The moment the Sun returns to its natal longitude (tropical, apparent of date).
class SolarReturn {
  /// Natal Sun longitude, degrees.
  final double sunLon;

  /// Exact moment, Julian Day UT.
  final double jdUt;

  /// Completed years of life at the return (1 = first birthday).
  final int age;

  /// Birth year + [age]: the year of the birthday the return belongs to.
  final int year;
  const SolarReturn(this.sunLon, this.jdUt, this.age, this.year);

  /// Return to [sunLon] nearest to [approxJdUt] (within ± 3 days).
  /// Newton steps on the mean solar motion, then bisection to under one second.
  static double find(double sunLon, double approxJdUt) {
    double f(double t) => angDiff(Ephemeris.longitude(Body.sun, t), sunLon);
    var t = approxJdUt;
    for (var i = 0; i < 4; i++) {
      t -= f(t) / 0.9856;
    }
    var a = t - 60 / 86400, b = t + 60 / 86400;
    while (f(a) > 0) {
      a -= 60 / 86400;
    }
    while (f(b) < 0) {
      b += 60 / 86400;
    }
    while ((b - a) * 86400 > 0.5) {
      final m = (a + b) / 2;
      if (f(m) < 0) {
        a = m;
      } else {
        b = m;
      }
    }
    return (a + b) / 2;
  }

  /// Solar return at the birthday of [age] years.
  factory SolarReturn.ofAge(Chart natal, int age) {
    final sun = natal.positions[Body.sun]!.lon;
    return SolarReturn(sun, find(sun, natal.time.jdUt + age * tropicalYearDays), age, natal.birth.moment.year + age);
  }

  /// Solar return of the birthday in [year] (birth year + age; a birthday
  /// on 1 January may return on 31 December UT of the year before).
  factory SolarReturn.ofYear(Chart natal, int year) => SolarReturn.ofAge(natal, year - natal.birth.moment.year);

  /// The return that starts the solar year containing [lifeJd].
  factory SolarReturn.current(Chart natal, double lifeJd) {
    final k = ((lifeJd - natal.time.jdUt) / tropicalYearDays).floor();
    final r = SolarReturn.ofAge(natal, k);
    if (r.jdUt > lifeJd) return SolarReturn.ofAge(natal, k - 1);
    final next = SolarReturn.ofAge(natal, k + 1);
    return next.jdUt <= lifeJd ? next : r;
  }

  /// Chart of the return moment at [place] (residence by default, plan decision 17).
  /// Without a house system the default for the place's latitude applies.
  Chart chartAt(GeoLocation place, {ChartOptions options = const ChartOptions()}) {
    final u = dateTimeUtcFromJd(jdUt);
    final birth = BirthData(
      moment: LocalMoment(year: u.year, month: u.month, day: u.day, hour: u.hour, minute: u.minute, basis: TimeBasis.ut),
      lat: place.lat,
      lon: place.lon,
      placeName: place.name,
    );
    final time = ResolvedTime(jdUt: jdUt, offsetHours: 0, basisUsed: TimeBasis.ut, abbreviation: 'UT');
    return Chart.computeAt(birth, time, options: options);
  }
}

/// Angles of a solar-return chart for `solar_return/planet_on_angle/{planet}/{angle}`.
enum ReturnAngle { asc, ic, dsc, mc }

/// Planets within [solarReturnAngleOrb] of a solar-return angle.
List<({Body body, ReturnAngle angle, double orb})> planetsOnAngles(Chart sr) {
  final h = sr.houses;
  if (h == null) return const [];
  final angles = {
    ReturnAngle.asc: h.asc,
    ReturnAngle.ic: norm360(h.mc + 180),
    ReturnAngle.dsc: norm360(h.asc + 180),
    ReturnAngle.mc: h.mc,
  };
  final out = <({Body body, ReturnAngle angle, double orb})>[];
  for (final b in Body.planets) {
    final p = sr.positions[b];
    if (p == null) continue;
    for (final a in angles.entries) {
      final d = angDist(p.lon, a.value);
      if (d <= solarReturnAngleOrb) out.add((body: b, angle: a.key, orb: d));
    }
  }
  out.sort((x, y) => x.orb.compareTo(y.orb));
  return out;
}
