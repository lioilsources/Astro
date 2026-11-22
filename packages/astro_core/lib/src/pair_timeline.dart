import 'dart:math' as math;

import 'aspects.dart';
import 'chart.dart';
import 'model.dart';
import 'transits.dart';

/// One transit configuration over its whole series of passes (plan R9, 4.2):
/// consecutive stays of the same body, target, aspect and side closer than
/// [TransitEngine.seriesGap] joined into one period.
class TransitSeries {
  final Body transiting;
  final ChartPoint target;
  final AspectType type;
  final int side;
  final double start;
  final double end;
  final List<double> exacts;
  final double? station;
  final List<TransitEvent> stays;
  const TransitSeries(this.transiting, this.target, this.type, this.side, this.start, this.end, this.exacts, this.station, this.stays);

  bool overlaps(double from, double to) => end >= from && start <= to;
}

/// Joins stays of one configuration into series (see [TransitSeries]).
List<TransitSeries> transitSeriesOf(List<TransitEvent> events) {
  final groups = <String, List<TransitEvent>>{};
  for (final e in events) {
    groups.putIfAbsent('${e.transiting.name}|${e.target.id}|${e.type.name}|${e.side}', () => []).add(e);
  }
  final out = <TransitSeries>[];
  for (final g in groups.values) {
    g.sort((a, b) => a.start.compareTo(b.start));
    var cur = <TransitEvent>[];
    void close() {
      if (cur.isEmpty) return;
      final f = cur.first;
      final stations = [for (final s in cur) if (s.station != null) s.station!];
      out.add(TransitSeries(
        f.transiting,
        f.target,
        f.type,
        f.side,
        f.start,
        cur.map((s) => s.end).reduce(math.max),
        [for (final s in cur) ...s.exacts],
        stations.isEmpty ? null : stations.first,
        cur,
      ));
      cur = [];
    }

    for (final e in g) {
      if (cur.isNotEmpty && e.start - cur.last.end > TransitEngine.seriesGap(e.transiting)) close();
      cur.add(e);
    }
    close();
  }
  out.sort((a, b) => a.start.compareTo(b.start));
  return out;
}

/// What a period means for the pair (plan R9, 4.2).
enum PairPeriodKind {
  /// Slow planet on Sun, Moon, Venus, Mars or the axis of relationship.
  strain,

  /// Slow planet to its own natal place (Saturn return, Uranus opposition…).
  cycle,

  /// Jupiter on a personal point.
  support,
}

/// Turning points of a life: transiting planet to its own natal place.
const pairCycles = <({String id, Body body, AspectType type})>[
  (id: 'saturn_return', body: Body.saturn, type: AspectType.conjunction),
  (id: 'saturn_opposition', body: Body.saturn, type: AspectType.opposition),
  (id: 'saturn_square', body: Body.saturn, type: AspectType.square),
  (id: 'uranus_opposition', body: Body.uranus, type: AspectType.opposition),
  (id: 'uranus_square', body: Body.uranus, type: AspectType.square),
  (id: 'neptune_square', body: Body.neptune, type: AspectType.square),
  (id: 'pluto_square', body: Body.pluto, type: AspectType.square),
  (id: 'jupiter_return', body: Body.jupiter, type: AspectType.conjunction),
];

const pairSlowBodies = [Body.saturn, Body.uranus, Body.neptune, Body.pluto];
const pairPersonalBodies = [Body.sun, Body.moon, Body.venus, Body.mars];

/// Minimum overlap of two strain periods of both people to count as shared, days.
const pairSharedMinDays = 30.0;

/// Minimum length of a calmer window, days.
const pairCalmMinDays = 90.0;

class PairPeriod {
  /// True when the period belongs to the first person of the pair.
  final bool ofFirst;
  final PairPeriodKind kind;
  final TransitSeries series;

  /// Cycle id from [pairCycles] for [PairPeriodKind.cycle] and the Jupiter return.
  final String? cycle;
  final int weight;

  /// The other person has a strain period overlapping this one by [pairSharedMinDays].
  final bool shared;
  const PairPeriod(this.ofFirst, this.kind, this.series, this.cycle, this.weight, {this.shared = false});

  double get start => series.start;
  double get end => series.end;

  /// Strain or a hard cycle (the Jupiter return is support).
  bool get isStraining => kind == PairPeriodKind.strain || (kind == PairPeriodKind.cycle && cycle != 'jupiter_return');

  PairPeriod withShared(bool v) => PairPeriod(ofFirst, kind, series, cycle, weight, shared: v);
}

/// Saturn or Jupiter entering the 7th house of one person.
class PairHouseIngress {
  final bool ofFirst;
  final Body body;
  final double jd;
  const PairHouseIngress(this.ofFirst, this.body, this.jd);
}

class CalmWindow {
  final double start;
  final double end;
  const CalmWindow(this.start, this.end);
}

class PairTimeline {
  final double from;
  final double to;

  /// Sorted by start.
  final List<PairPeriod> periods;
  final List<PairHouseIngress> ingresses;
  final List<CalmWindow> calm;
  const PairTimeline(this.from, this.to, this.periods, this.ingresses, this.calm);

  /// Periods running at [jd].
  List<PairPeriod> at(double jd) => [for (final p in periods) if (p.start <= jd && p.end >= jd) p];

  /// Straining periods that end after [jd], nearest first.
  List<PairPeriod> nextStraining(double jd) =>
      [for (final p in periods) if (p.isStraining && p.end >= jd) p]..sort((a, b) => a.start.compareTo(b.start));

  /// Slow transits on the sensitive points of both charts over [from, to] (plan R9, 4.2).
  static PairTimeline compute(Chart first, Chart second, double from, double to) {
    final periods = [..._periodsOf(first, true, from, to), ..._periodsOf(second, false, from, to)];
    final marked = [
      for (final p in periods)
        p.isStraining
            ? p.withShared(periods.any((o) => o.ofFirst != p.ofFirst && o.isStraining && _overlap(p, o) >= pairSharedMinDays))
            : p,
    ]..sort((a, b) => a.start.compareTo(b.start));
    return PairTimeline(from, to, marked, [..._ingressesOf(first, true, from, to), ..._ingressesOf(second, false, from, to)]
      ..sort((a, b) => a.jd.compareTo(b.jd)), calmWindows(marked, from, to));
  }

  static double _overlap(PairPeriod a, PairPeriod b) => math.min(a.end, b.end) - math.max(a.start, b.start);

  /// Gaps of at least [pairCalmMinDays] inside [from, to] without any straining period.
  static List<CalmWindow> calmWindows(List<PairPeriod> periods, double from, double to) {
    final busy = [for (final p in periods) if (p.isStraining) (math.max(p.start, from), math.min(p.end, to))]
      ..sort((a, b) => a.$1.compareTo(b.$1));
    final out = <CalmWindow>[];
    var t = from;
    for (final (s, e) in busy) {
      if (s - t >= pairCalmMinDays) out.add(CalmWindow(t, s));
      if (e > t) t = e;
    }
    if (to - t >= pairCalmMinDays) out.add(CalmWindow(t, to));
    return out;
  }

  static List<PairPeriod> _periodsOf(Chart natal, bool ofFirst, double from, double to) {
    final timeKnown = natal.houses != null;
    const asc = ChartPoint.angle(Angle.asc);
    // Without a birth time the Moon's place is uncertain by more than the orb.
    final personal = {
      for (final b in pairPersonalBodies)
        if (natal.positions.containsKey(b) && (timeKnown || b != Body.moon)) ChartPoint.body(b),
    };
    const movers = [...pairSlowBodies, Body.jupiter];
    // One ephemeris pass per planet: every target and aspect at once, sorted out below.
    final events = TransitEngine(natal).events(from, to,
        bodies: movers,
        only: {...personal, if (timeKnown) asc, for (final b in movers) ChartPoint.body(b)},
        types: const [AspectType.conjunction, AspectType.square, AspectType.trine, AspectType.opposition]);
    final out = <PairPeriod>[];
    for (final s in transitSeriesOf(events)) {
      if (!s.overlaps(from, to)) continue;
      final (kind, cycle) = _classify(s, personal);
      if (kind != null) out.add(PairPeriod(ofFirst, kind, s, cycle, pairPeriodWeight(s)));
    }
    return out;
  }

  static (PairPeriodKind?, String?) _classify(TransitSeries s, Set<ChartPoint> personal) {
    final t = s.target, type = s.type;
    if (t.body == s.transiting) {
      for (final c in pairCycles) {
        if (c.body == s.transiting && c.type == type) {
          return (c.body == Body.jupiter ? PairPeriodKind.support : PairPeriodKind.cycle, c.id);
        }
      }
      return (null, null);
    }
    final axis = t.isAngle && (type == AspectType.conjunction || type == AspectType.opposition);
    if (s.transiting == Body.jupiter) {
      final ok = axis || (personal.contains(t) && (type == AspectType.conjunction || type == AspectType.trine));
      return (ok ? PairPeriodKind.support : null, null);
    }
    final ok = axis || (personal.contains(t) && type != AspectType.trine);
    return (ok ? PairPeriodKind.strain : null, null);
  }

  static List<PairHouseIngress> _ingressesOf(Chart natal, bool ofFirst, double from, double to) {
    final out = <PairHouseIngress>[];
    final last = <Body, double>{};
    for (final i in TransitEngine(natal).ingresses(from, to, bodies: const [Body.jupiter, Body.saturn])) {
      if (i.house != 7 || i.retrograde) continue;
      // A retrograde loop over the cusp gives a second direct entry: keep the first.
      final prev = last[i.body];
      if (prev != null && i.jd - prev < 365) continue;
      last[i.body] = i.jd;
      out.add(PairHouseIngress(ofFirst, i.body, i.jd));
    }
    return out;
  }
}

/// Order of periods (docs/scoring.md, plan R9 4.2); not a score of the relationship.
int pairPeriodWeight(TransitSeries s) {
  final t = s.target;
  final big = t.isAngle || const {Body.sun, Body.moon, Body.venus}.contains(t.body);
  final own = t.body == s.transiting;
  return TransitEngine.slowness(s.transiting) +
      (big && !own ? 15 : 5) +
      (s.station != null ? 10 : 0) +
      (s.exacts.length >= 3 ? 5 : 0);
}
