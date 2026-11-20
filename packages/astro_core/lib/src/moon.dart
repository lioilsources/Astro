import 'dart:math' as math;

import 'package:astronomia/eclipse.dart' as eclipse;

import 'angles.dart';
import 'aspects.dart';
import 'chart.dart';
import 'ephemeris.dart';
import 'model.dart';
import 'time.dart';
import 'track.dart';

/// Eight phases of the Moon as 45° sectors of the elongation Moon − Sun,
/// each starting at its principal point (D. Rudhyar's lunation cycle):
/// new 0°–45°, crescent 45°–90°, first quarter 90°–135° … balsamic 315°–360°.
enum MoonPhase {
  newMoon('new'),
  crescent('crescent'),
  firstQuarter('first_quarter'),
  gibbous('gibbous'),
  fullMoon('full'),
  disseminating('disseminating'),
  lastQuarter('last_quarter'),
  balsamic('balsamic');

  /// Content id (`moon_phase/{id}`, `natal_moon_phase/{id}`).
  final String id;
  const MoonPhase(this.id);

  static MoonPhase ofElongation(double elongation) => MoonPhase.values[norm360(elongation) ~/ 45];

  bool get waxing => index < 4;
}

/// Exact quarter points of the lunation cycle.
enum LunationKind {
  newMoon(0),
  firstQuarter(90),
  fullMoon(180),
  lastQuarter(270);

  final double elongation;
  const LunationKind(this.elongation);
}

enum EclipseKind { solar, lunar }

enum EclipseDegree { penumbral, partial, annular, hybrid, total }

/// Eclipse flag of a new or full moon (global, no local visibility).
class Eclipse {
  final EclipseKind kind;
  final EclipseDegree degree;

  /// Greatest eclipse, Julian Day UT.
  final double jdMax;
  const Eclipse(this.kind, this.degree, this.jdMax);
  @override
  String toString() => '${degree.name} ${kind.name} eclipse at $jdMax';
}

/// An exact new moon, quarter or full moon.
class Lunation {
  final LunationKind kind;

  /// Julian Day UT.
  final double jd;

  /// Longitude of the Moon at that moment (the lunation point).
  final double lon;

  /// Set for new and full moons that are eclipses.
  final Eclipse? eclipse;
  const Lunation(this.kind, this.jd, this.lon, this.eclipse);

  Sign get sign => Sign.ofLongitude(lon);
  bool get isNewOrFull => kind == LunationKind.newMoon || kind == LunationKind.fullMoon;
  @override
  String toString() => '${kind.name} $jd ${lon.toStringAsFixed(2)}${eclipse != null ? ' $eclipse' : ''}';
}

/// The Moon entering a sign.
class MoonIngress {
  final double jd;
  final Sign sign;
  const MoonIngress(this.jd, this.sign);
  @override
  String toString() => 'Moon → ${sign.name} at $jd';
}

/// The last major aspect the Moon perfects with a planet.
class MoonAspect {
  final Body body;
  final AspectType type;
  final double jd;
  const MoonAspect(this.body, this.type, this.jd);
  @override
  String toString() => 'Moon ${type.name} ${body.name} at $jd';
}

/// Void-of-course Moon: from its last major aspect in a sign until it enters
/// the next sign (plan 10.2).
class VoidOfCourse {
  /// Julian Days UT. When the Moon makes no aspect in the whole sign,
  /// [start] is the ingress into that sign and [lastAspect] is null.
  final double start;
  final double end;

  /// Sign the Moon is void in.
  final Sign sign;
  final MoonAspect? lastAspect;
  const VoidOfCourse(this.start, this.end, this.sign, this.lastAspect);

  Sign get nextSign => Sign.values[(sign.index + 1) % 12];
  bool covers(double jd) => jd >= start && jd < end;
  double get hours => (end - start) * 24;
  @override
  String toString() => 'VoC ${sign.name} [$start … $end) after $lastAspect';
}

/// Moon phases, lunations, eclipses, sign ingresses and void of course.
class Lunar {
  Lunar._();

  /// Elongation of the Moon from the Sun in longitude, 0..360 (UT).
  static double elongation(double jdUt) => norm360(Ephemeris.longitude(Body.moon, jdUt) - Ephemeris.longitude(Body.sun, jdUt));

  static MoonPhase phaseAt(double jdUt) => MoonPhase.ofElongation(elongation(jdUt));

  /// Exact lunations in [from, to) (Julian Days UT), by bisection of the
  /// elongation to about one second.
  static List<Lunation> lunations(double from, double to, {Set<LunationKind>? kinds}) {
    final want = kinds ?? LunationKind.values.toSet();
    final out = <Lunation>[];
    const step = 1.0;
    var t0 = from;
    var e0 = elongation(t0);
    while (t0 < to) {
      final t1 = math.min(t0 + step, to);
      final e1 = elongation(t1);
      // Elongation grows 11–15°/day, so at most one quarter point per step.
      final q0 = e0 ~/ 90, q1 = e1 ~/ 90;
      if (q0 != q1) {
        final kind = LunationKind.values[q1];
        if (want.contains(kind)) {
          double f(double t) => angDiff(elongation(t), kind.elongation);
          var a = t0, b = t1;
          for (var i = 0; i < 20; i++) {
            final m = (a + b) / 2;
            if (f(m) < 0) {
              a = m;
            } else {
              b = m;
            }
          }
          final jd = (a + b) / 2;
          out.add(Lunation(kind, jd, Ephemeris.longitude(Body.moon, jd), eclipseAt(kind, jd)));
        }
      }
      t0 = t1;
      e0 = e1;
    }
    return out;
  }

  /// Eclipse at a new or full moon at [jdUt], from Meeus ch. 54 (`astronomia`).
  static Eclipse? eclipseAt(LunationKind kind, double jdUt) {
    if (kind != LunationKind.newMoon && kind != LunationKind.fullMoon) return null;
    final year = decimalYearOfJd(jdUt);
    final dt = deltaTSeconds(year) / 86400;
    if (kind == LunationKind.newMoon) {
      final r = eclipse.solar(year);
      if (r.type == eclipse.none || (r.jmax - dt - jdUt).abs() > 1) return null;
      final degree = switch (r.type) {
        eclipse.total => EclipseDegree.total,
        eclipse.annular => EclipseDegree.annular,
        eclipse.annularTotal => EclipseDegree.hybrid,
        _ => EclipseDegree.partial,
      };
      return Eclipse(EclipseKind.solar, degree, r.jmax - dt);
    }
    final r = eclipse.lunar(year);
    if (r.type == eclipse.none || (r.jmax - dt - jdUt).abs() > 1) return null;
    final degree = switch (r.type) {
      eclipse.total => EclipseDegree.total,
      eclipse.umbral => EclipseDegree.partial,
      _ => EclipseDegree.penumbral,
    };
    return Eclipse(EclipseKind.lunar, degree, r.jmax - dt);
  }

  /// The Moon's sign ingresses in [from, to), bisected to about one second.
  static List<MoonIngress> ingresses(double from, double to) =>
      _ingresses(LongitudeTrack.build(Body.moon, from, to, _moonStep), from, to);

  static const _moonStep = 1 / 24;

  static List<MoonIngress> _ingresses(LongitudeTrack track, double from, double to) {
    final out = <MoonIngress>[];
    var t0 = from;
    var s0 = track.at(t0) ~/ 30;
    while (t0 < to) {
      final t1 = math.min(t0 + _moonStep, to);
      final s1 = track.at(t1) ~/ 30;
      if (s1 != s0) {
        var a = t0, b = t1;
        for (var i = 0; i < 14; i++) {
          final m = (a + b) / 2;
          if (track.at(m) ~/ 30 == s0) {
            a = m;
          } else {
            b = m;
          }
        }
        out.add(MoonIngress((a + b) / 2, Sign.values[s1]));
      }
      t0 = t1;
      s0 = s1;
    }
    return out;
  }

  /// Planets the void-of-course rule looks at: Sun–Pluto, or the
  /// traditional Sun–Saturn when [traditionalOnly].
  static List<Body> vocBodies({bool traditionalOnly = false}) =>
      [for (final b in traditionalOnly ? Body.traditional : Body.planets) if (b != Body.moon) b];

  /// Void-of-course periods overlapping [from, to) (Julian Days UT).
  static List<VoidOfCourse> voidOfCourse(double from, double to, {bool traditionalOnly = false}) {
    // The Moon stays at most ~2.7 days in a sign: start early enough to see
    // the ingress that begins any period overlapping [from, to).
    final t0 = from - 3, t1 = to + 3;
    final moon = LongitudeTrack.build(Body.moon, t0, t1, _moonStep);
    final planets = [
      for (final b in vocBodies(traditionalOnly: traditionalOnly))
        if (Ephemeris.available(b, t0) && Ephemeris.available(b, t1)) LongitudeTrack.build(b, t0, t1, 0.5),
    ];
    final ing = _ingresses(moon, t0, t1);
    final out = <VoidOfCourse>[];
    for (var k = 0; k + 1 < ing.length; k++) {
      final a = ing[k].jd, b = ing[k + 1].jd;
      if (b < from || a >= to) continue;
      final last = _lastAspect(moon, planets, a, b);
      out.add(VoidOfCourse(last?.jd ?? a, b, ing[k].sign, last));
    }
    return [for (final v in out) if (v.end > from && v.start < to) v];
  }

  /// Void-of-course period at [jdUt], or null when the Moon is not void.
  static VoidOfCourse? voidAt(double jdUt, {bool traditionalOnly = false}) =>
      voidOfCourse(jdUt, jdUt + 1e-6, traditionalOnly: traditionalOnly).where((v) => v.covers(jdUt)).firstOrNull;

  static MoonAspect? _lastAspect(LongitudeTrack moon, List<LongitudeTrack> planets, double a, double b) {
    MoonAspect? best;
    for (final p in planets) {
      for (final type in AspectType.major) {
        for (final side in (type == AspectType.conjunction || type == AspectType.opposition) ? const [1] : const [1, -1]) {
          double f(double t) => angDiff(angDiff(moon.at(t), p.at(t)), side * type.angle);
          var t = a;
          var f0 = f(t);
          while (t < b) {
            final t2 = math.min(t + _moonStep, b);
            final f2 = f(t2);
            if (f0.abs() < 90 && f2.abs() < 90 && f0 < 0 && f2 >= 0) {
              var lo = t, hi = t2;
              for (var i = 0; i < 14; i++) {
                final m = (lo + hi) / 2;
                if (f(m) < 0) {
                  lo = m;
                } else {
                  hi = m;
                }
              }
              final jd = (lo + hi) / 2;
              if (best == null || jd > best.jd) best = MoonAspect(p.body, type, jd);
            }
            t = t2;
            f0 = f2;
          }
        }
      }
    }
    return best;
  }
}

/// Phase of the Moon at birth.
MoonPhase? natalMoonPhase(Chart c) {
  final m = c.positions[Body.moon], s = c.positions[Body.sun];
  if (m == null || s == null) return null;
  return MoonPhase.ofElongation(m.lon - s.lon);
}

/// Natal house a lunation falls in (null without birth time).
int? lunationHouse(Chart natal, Lunation l) {
  final h = natal.houses;
  if (h == null || !h.defined) return null;
  return h.houseOf(l.lon);
}
