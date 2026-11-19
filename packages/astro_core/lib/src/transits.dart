import 'dart:math' as math;

import 'angles.dart';
import 'aspects.dart';
import 'chart.dart';
import 'ephemeris.dart';
import 'model.dart';
import 'track.dart';

enum TransitLayer { background, weeks, days, hours }

enum TransitPhase { approaching, exact, separating }

TransitLayer layerOf(Body b) => switch (b) {
      Body.saturn || Body.uranus || Body.neptune || Body.pluto => TransitLayer.background,
      Body.mars || Body.jupiter => TransitLayer.weeks,
      Body.moon => TransitLayer.hours,
      _ => TransitLayer.days,
    };

/// One contiguous stay of a transiting body within orb of an aspect to a natal point.
class TransitEvent {
  final Body transiting;
  final ChartPoint target;
  final AspectType type;

  /// +1 or −1: which side of the target (the same aspect angle can be made from both sides).
  final int side;

  /// Entry into and exit from the orb, Julian Day UT.
  final double start;
  final double end;

  /// Exact moments inside the stay (several when the body turns retrograde in orb).
  final List<double> exacts;

  /// Ordinal of each exact moment within its series (1., 2., 3. pass).
  final List<int> passNumbers;

  /// Number of exact passes in the whole series (null when the series leaves the computed range).
  final int? passTotal;

  /// Station (turn direct/retrograde) inside the stay.
  final double? station;

  const TransitEvent({
    required this.transiting,
    required this.target,
    required this.type,
    required this.side,
    required this.start,
    required this.end,
    required this.exacts,
    required this.passNumbers,
    required this.passTotal,
    required this.station,
  });

  TransitLayer get layer => layerOf(transiting);
  bool covers(double jd) => jd >= start && jd <= end;
  String get id => '${transiting.name}-${type.name}-${target.id}-${start.toStringAsFixed(4)}';

  /// The exact moment nearest to [jd], if any.
  double? nearestExact(double jd) {
    if (exacts.isEmpty) return null;
    return exacts.reduce((a, b) => (a - jd).abs() <= (b - jd).abs() ? a : b);
  }

  @override
  String toString() => '${transiting.name} ${type.name} ${target.id} [$start … $end] exacts $exacts passes $passNumbers/$passTotal'
      '${station != null ? ' station $station' : ''}';
}

/// Transiting body entering a natal house.
class HouseIngress {
  final Body body;
  final int house;
  final double jd;
  final bool retrograde;
  const HouseIngress(this.body, this.house, this.jd, this.retrograde);
  @override
  String toString() => '${body.name} → house $house at $jd${retrograde ? ' R' : ''}';
}

/// Finds transits of moving planets to the points of a natal chart (plan 3.4).
class TransitEngine {
  final Chart natal;
  final OrbConfig orbs;
  TransitEngine(this.natal, {OrbConfig? orbs}) : orbs = orbs ?? natal.options.orbs;

  /// Natal targets: the ten planets, ASC and MC when the birth time is known.
  List<ChartPoint> get targets => [
        for (final b in Body.planets)
          if (natal.positions.containsKey(b)) ChartPoint.body(b),
        if (natal.houses != null) const ChartPoint.angle(Angle.asc),
        if (natal.houses != null) const ChartPoint.angle(Angle.mc),
      ];

  /// Sampling step for detection; bisection then runs on the interpolated track.
  static double stepDays(Body b) => switch (b) {
        Body.moon => 1 / 24,
        Body.sun || Body.mercury || Body.venus => 0.5,
        Body.mars => 1,
        _ => 2,
      };

  /// How far outside the requested range a stay may begin or end (retrograde loops).
  static double marginDays(Body b) => switch (b) {
        Body.moon => 0.5,
        Body.sun => 3,
        Body.mercury || Body.venus => 120,
        Body.mars => 200,
        Body.jupiter => 250,
        _ => 400,
      };

  /// Series gap: exact passes further apart than this start a new series.
  static double seriesGap(Body b) => switch (b) {
        Body.moon => 2,
        Body.sun => 30,
        Body.mercury || Body.venus => 90,
        Body.mars => 150,
        Body.jupiter => 200,
        _ => 300,
      };

  double _lon(Body b, double jd) => Ephemeris.longitude(b, jd);

  /// Signed deviation of the configuration from exact, degrees.
  double _dev(double lonT, double lonN, AspectType t, int side) => angDiff(angDiff(lonT, lonN), side * t.angle);

  /// Events whose stay overlaps [from, to] (Julian Days UT).
  List<TransitEvent> events(double from, double to, {Iterable<Body>? bodies}) {
    final out = <TransitEvent>[];
    final tg = targets;
    for (final body in bodies ?? Body.planets) {
      if (!Ephemeris.available(body, from)) continue;
      final m = marginDays(body);
      final h = stepDays(body);
      final t0 = from - m, t1 = to + m;
      final track = LongitudeTrack.build(body, t0, t1, h);
      final idx = [for (var i = 1; i < track.length - 2; i++) i];
      final ts = [for (final i in idx) track.timeAt(i)];
      final lons = [for (final i in idx) track.sample(i)];
      for (final target in tg) {
        final lonN = natal.lonOf(target)!;
        for (final type in AspectType.major) {
          for (final side in (type == AspectType.conjunction || type == AspectType.opposition) ? const [1] : const [1, -1]) {
            final raw = _stays(body, track, ts, lons, lonN, type, side);
            out.addAll(_number(body, target, type, side, raw, from, to, t0, t1));
          }
        }
      }
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  List<({double start, double end, List<double> exacts, double? station})> _stays(
      Body body, LongitudeTrack track, List<double> ts, List<double> lons, double lonN, AspectType type, int side) {
    final orb = orbs.transitOrb;
    final out = <({double start, double end, List<double> exacts, double? station})>[];
    double dev(int i) => _dev(lons[i], lonN, type, side);
    double devAt(double t) => _dev(track.at(t), lonN, type, side);
    bool inOrb(double d) => d.abs() <= orb;
    // Ignore samples far from this configuration (avoids wrap artefacts at ±180°).
    int i = 0;
    while (i < ts.length) {
      if (!inOrb(dev(i))) {
        i++;
        continue;
      }
      // Entry
      final start = i == 0 ? ts[0] : _bisect((t) => inOrb(devAt(t)), ts[i - 1], ts[i], wantTrueAtHi: true);
      var j = i;
      while (j + 1 < ts.length && inOrb(dev(j + 1))) {
        j++;
      }
      final end = j + 1 >= ts.length ? ts.last : _bisect((t) => inOrb(devAt(t)), ts[j], ts[j + 1], wantTrueAtHi: false);
      final exacts = <double>[];
      double? station;
      final lo = math.max(0, i - 1), hi = math.min(ts.length - 1, j + 1);
      for (var k = lo; k < hi; k++) {
        final a = dev(k), b = dev(k + 1);
        if (a.abs() < 90 && b.abs() < 90 && (a == 0 || a.sign != b.sign)) {
          final te = _root((t) => devAt(t), ts[k], ts[k + 1]);
          if (te >= start - 1e-9 && te <= end + 1e-9) exacts.add(te);
        }
        if (k > lo) {
          final s1 = angDiff(lons[k], lons[k - 1]), s2 = angDiff(lons[k + 1], lons[k]);
          if (s1.sign != s2.sign && body != Body.sun && body != Body.moon) {
            final ts0 = ts[k - 1], ts1 = ts[k + 1];
            final st = _stationTime(track, ts0, ts1);
            if (st >= start && st <= end) station = st;
          }
        }
      }
      out.add((start: start, end: end, exacts: exacts, station: station));
      i = j + 1;
    }
    return out;
  }

  List<TransitEvent> _number(Body body, ChartPoint target, AspectType type, int side,
      List<({double start, double end, List<double> exacts, double? station})> stays, double from, double to, double t0, double t1) {
    // Series of exact passes: consecutive exacts closer than the series gap.
    final allExacts = [for (final s in stays) ...s.exacts];
    final passNo = <double, int>{};
    final seriesTotal = <double, int?>{};
    var series = <double>[];
    void close(bool openEnded) {
      final neverRetrograde = body == Body.sun || body == Body.moon;
      for (final (k, e) in series.indexed) {
        passNo[e] = k + 1;
        seriesTotal[e] = neverRetrograde ? 1 : (openEnded ? null : series.length);
      }
      series = [];
    }

    for (final e in allExacts) {
      if (series.isNotEmpty && e - series.last > seriesGap(body)) close(series.first - t0 < seriesGap(body));
      series.add(e);
    }
    if (series.isNotEmpty) close(t1 - series.last < seriesGap(body) || series.first - t0 < seriesGap(body));

    return [
      for (final s in stays)
        if (s.end >= from && s.start <= to)
          TransitEvent(
            transiting: body,
            target: target,
            type: type,
            side: side,
            start: s.start,
            end: s.end,
            exacts: s.exacts,
            passNumbers: [for (final e in s.exacts) passNo[e]!],
            passTotal: s.exacts.isEmpty ? null : seriesTotal[s.exacts.first],
            station: s.station,
          ),
    ];
  }

  /// Bisection to one minute on a boolean predicate that changes between lo and hi.
  static double _bisect(bool Function(double) p, double lo, double hi, {required bool wantTrueAtHi}) {
    var a = lo, b = hi;
    while (b - a > 1 / 1440) {
      final m = (a + b) / 2;
      if (p(m) == wantTrueAtHi) {
        b = m;
      } else {
        a = m;
      }
    }
    return wantTrueAtHi ? b : a;
  }

  /// Root of a continuous signed function between lo and hi (sign change), to ~1 s.
  static double _root(double Function(double) f, double lo, double hi) {
    var a = lo, b = hi;
    var fa = f(a);
    for (var i = 0; i < 40 && b - a > 1 / 86400; i++) {
      final m = (a + b) / 2;
      final fm = f(m);
      if (fm == 0) return m;
      if (fm.sign == fa.sign) {
        a = m;
        fa = fm;
      } else {
        b = m;
      }
    }
    return (a + b) / 2;
  }

  double _stationTime(LongitudeTrack track, double lo, double hi) {
    double speed(double t) => track.speedAt(t);
    final sLo = speed(lo);
    var a = lo, b = hi;
    for (var i = 0; i < 30 && b - a > 1 / 1440; i++) {
      final m = (a + b) / 2;
      if (speed(m).sign == sLo.sign) {
        a = m;
      } else {
        b = m;
      }
    }
    return (a + b) / 2;
  }

  /// Deviation from exact at [jd], degrees (signed).
  double deviationAt(TransitEvent e, double jd) => _dev(_lon(e.transiting, jd), natal.lonOf(e.target)!, e.type, e.side);

  /// Half-width of the "exact" window: deviation ≤ 0.2° (time = 0.2° / speed).
  static const exactWindowDeg = 0.2;

  TransitPhase phaseAt(TransitEvent e, double jd) {
    final d = deviationAt(e, jd).abs();
    if (d <= exactWindowDeg) return TransitPhase.exact;
    final ex = e.nearestExact(jd);
    if (ex != null) return jd < ex ? TransitPhase.approaching : TransitPhase.separating;
    // Near miss: compare with the moment of the smallest deviation (middle of the stay).
    final d2 = deviationAt(e, jd + 0.01).abs();
    return d2 < d ? TransitPhase.approaching : TransitPhase.separating;
  }

  static const _slowness = {
    Body.pluto: 25, Body.neptune: 23, Body.uranus: 21, Body.saturn: 18, Body.jupiter: 14,
    Body.mars: 10, Body.sun: 7, Body.venus: 6, Body.mercury: 5, Body.moon: 2,
  };

  /// Strength 0–100 at [jd] (docs/scoring.md). [concurrent] = other events active at jd.
  int strengthAt(TransitEvent e, double jd, {Iterable<TransitEvent> concurrent = const []}) {
    final d = deviationAt(e, jd).abs();
    final tight = (1 - (d / orbs.transitOrb)).clamp(0.0, 1.0);
    var s = 35 * tight + (_slowness[e.transiting] ?? 0);
    if (e.target.isPersonal) s += 15;
    if (e.type.quality != AspectQuality.harmonious) s += 5;
    if (e.station != null && (e.station! - jd).abs() < 10) s += 10;
    final others = concurrent.where((o) => o != e && o.target == e.target && o.covers(jd) && o.transiting != Body.moon).length;
    s += math.min(10, others * 5);
    return s.round().clamp(0, 100);
  }

  static bool isAcute(int strength) => strength >= 70;

  /// Natal house ingresses of transiting planets within [from, to].
  List<HouseIngress> ingresses(double from, double to, {Iterable<Body>? bodies}) {
    final h = natal.houses;
    if (h == null || !h.defined) return const [];
    final out = <HouseIngress>[];
    for (final body in bodies ?? Body.planets) {
      if (!Ephemeris.available(body, from)) continue;
      final step = stepDays(body);
      final track = LongitudeTrack.build(body, from, to, step);
      var t = from;
      var house = h.houseOf(track.at(t));
      while (t < to) {
        final t2 = math.min(t + step, to);
        final h2 = h.houseOf(track.at(t2));
        if (h2 != house) {
          final at = _bisect((x) => h.houseOf(track.at(x)) == h2, t, t2, wantTrueAtHi: true);
          final retro = track.speedAt(at) < 0;
          out.add(HouseIngress(body, h2, at, retro));
          house = h2;
        }
        t = t2;
      }
    }
    out.sort((a, b) => a.jd.compareTo(b.jd));
    return out;
  }

  /// Tension for every day (noon UT) from [from] for [days] days, using sampled tracks.
  List<double> tensionSeries(double from, int days) {
    final to = from + days;
    final tracks = <LongitudeTrack>[
      for (final b in Body.planets)
        if (b != Body.moon && Ephemeris.available(b, from) && Ephemeris.available(b, to))
          LongitudeTrack.build(b, from, to, _tensionStep[b]!),
    ];
    return [
      for (var d = 0; d < days; d++)
        _tension({for (final t in tracks) t.body: t.at(from + d)})
    ];
  }

  static const _tensionStep = {
    Body.sun: 4.0, Body.mercury: 2.0, Body.venus: 4.0, Body.mars: 8.0,
    Body.jupiter: 8.0, Body.saturn: 10.0, Body.uranus: 10.0, Body.neptune: 10.0, Body.pluto: 10.0,
  };

  /// Daily tension score used for the "how unusual was that day" percentile (plan 3.5 B).
  /// Sum of strengths of tense aspects and conjunctions in orb at [jd], Moon excluded.
  double tensionAt(double jd) => _tension({
        for (final b in Body.planets)
          if (b != Body.moon && Ephemeris.available(b, jd)) b: _lon(b, jd)
      });

  double _tension(Map<Body, double> lons) {
    var sum = 0.0;
    for (final MapEntry(key: body, value: lonT) in lons.entries) {
      for (final target in targets) {
        final lonN = natal.lonOf(target)!;
        for (final type in const [AspectType.conjunction, AspectType.square, AspectType.opposition]) {
          for (final side in type == AspectType.square ? const [1, -1] : const [1]) {
            final d = _dev(lonT, lonN, type, side).abs();
            if (d > orbs.transitOrb) continue;
            final tight = 1 - d / orbs.transitOrb;
            sum += 35 * tight + (_slowness[body] ?? 0) + (target.isPersonal ? 15 : 0);
          }
        }
      }
    }
    return sum;
  }
}
