import 'dart:math' as math;

import 'angles.dart';
import 'aspects.dart';
import 'ephemeris.dart';
import 'model.dart';
import 'moon.dart';
import 'track.dart';

/// Every major aspect the Moon perfects in a period, grouped by the sign it is
/// in, with the next and last aspect at any moment and the void-of-course
/// periods that follow from them (plan 10.2, 10.7; reused by horary, 10.8).
///
/// Built from the same tracks and with the same scan as [Lunar.voidOfCourse]
/// (Moon hourly, planets every 12 h, ±3 days around the period), so its voids
/// are identical to R2's.
class MoonAspectTimeline {
  final double from, to;
  final LongitudeTrack moon;

  /// Tracks of the planets the Moon aspects (Sun–Pluto or Sun–Saturn).
  final Map<Body, LongitudeTrack> planets;

  /// Sign ingresses of the Moon covering the period and its margins.
  final List<MoonIngress> ingresses;

  /// Perfections between ingress k and k + 1, sorted by time.
  final List<List<MoonAspect>> _bySign;

  MoonAspectTimeline._(this.from, this.to, this.moon, this.planets, this.ingresses, this._bySign);

  static const _moonStep = 1 / 24;
  static const _planetStep = 0.5;

  factory MoonAspectTimeline.build(double from, double to, {bool traditionalOnly = false}) {
    final t0 = from - 3, t1 = to + 3;
    final moon = LongitudeTrack.build(Body.moon, t0, t1, _moonStep);
    final planets = {
      for (final b in Lunar.vocBodies(traditionalOnly: traditionalOnly))
        if (Ephemeris.available(b, t0) && Ephemeris.available(b, t1)) b: LongitudeTrack.build(b, t0, t1, _planetStep),
    };
    final ing = _ingresses(moon, t0, t1);
    final bySign = [
      for (var k = 0; k + 1 < ing.length; k++) perfections(moon, planets.values, ing[k].jd, ing[k + 1].jd),
    ];
    return MoonAspectTimeline._(from, to, moon, planets, ing, bySign);
  }

  /// Longitude track of [b] (the Moon or one of [planets]).
  LongitudeTrack? track(Body b) => b == Body.moon ? moon : planets[b];

  /// Index k of the sign stay [ingress k, ingress k + 1) containing [jd], or −1.
  int _segment(double jd) {
    var lo = 0, hi = ingresses.length - 2;
    while (lo <= hi) {
      final m = (lo + hi) >> 1;
      if (jd < ingresses[m].jd) {
        hi = m - 1;
      } else if (jd >= ingresses[m + 1].jd) {
        lo = m + 1;
      } else {
        return m;
      }
    }
    return -1;
  }

  /// The next aspect the Moon perfects before leaving its sign, after [jd];
  /// null when the Moon is void of course (or [jd] is outside the timeline).
  MoonAspect? nextAspect(double jd) {
    final k = _segment(jd);
    if (k < 0) return null;
    for (final a in _bySign[k]) {
      if (a.jd > jd) return a;
    }
    return null;
  }

  /// The last aspect the Moon perfected in its sign up to [jd], if any.
  MoonAspect? lastAspect(double jd) {
    final k = _segment(jd);
    if (k < 0) return null;
    MoonAspect? out;
    for (final a in _bySign[k]) {
      if (a.jd > jd) break;
      out = a;
    }
    return out;
  }

  /// Void-of-course periods overlapping [from, to) of the timeline.
  late final List<VoidOfCourse> voids = [
    for (var k = 0; k < _bySign.length; k++)
      if (ingresses[k + 1].jd >= from && ingresses[k].jd < to)
        VoidOfCourse(_bySign[k].lastOrNull?.jd ?? ingresses[k].jd, ingresses[k + 1].jd, ingresses[k].sign, _bySign[k].lastOrNull),
  ].where((v) => v.end > from && v.start < to).toList();

  VoidOfCourse? voidAt(double jd) => voids.where((v) => v.covers(jd)).firstOrNull;

  /// True when some void-of-course period overlaps [a, b).
  bool voidOverlaps(double a, double b) => voids.any((v) => v.start < b && v.end > a);

  /// All perfections of major aspects between the Moon and [planets] in [a, b),
  /// sorted by time. Same scan as the void-of-course rule: hourly sign changes
  /// of the deviation, bisected to about 5 s.
  static List<MoonAspect> perfections(LongitudeTrack moon, Iterable<LongitudeTrack> planets, double a, double b) {
    final out = <MoonAspect>[];
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
              out.add(MoonAspect(p.body, type, (lo + hi) / 2));
            }
            t = t2;
            f0 = f2;
          }
        }
      }
    }
    out.sort((x, y) => x.jd.compareTo(y.jd));
    return out;
  }

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
}
