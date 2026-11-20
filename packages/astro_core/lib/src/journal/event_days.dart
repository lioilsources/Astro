import 'dart:math' as math;

/// Where one day's tension sits within a whole life (people catalog, plan 4.3).
///
/// [u] is the mid-rank share (0…1): days with lower tension plus half of the days with the
/// same tension, over all days. Ties are common (many days have zero tension), and the mid-rank
/// keeps the expectation of a random day at exactly 0.5.
/// [top20] is the chance that the day lands in the top 20 % of the life when ties are broken at
/// random (1 or 0 without ties); for a random day of the life its expectation is exactly 0.2.
class LifeRank {
  final double u;
  final double top20;
  const LifeRank(this.u, this.top20);

  int get percentile => (100 * u).round().clamp(0, 100);
}

int _lowerBound(List<double> s, double v) {
  var lo = 0, hi = s.length;
  while (lo < hi) {
    final m = (lo + hi) >> 1;
    if (s[m] < v) {
      lo = m + 1;
    } else {
      hi = m;
    }
  }
  return lo;
}

int _upperBound(List<double> s, double v) {
  var lo = 0, hi = s.length;
  while (lo < hi) {
    final m = (lo + hi) >> 1;
    if (s[m] <= v) {
      lo = m + 1;
    } else {
      hi = m;
    }
  }
  return lo;
}

/// Rank of [value] within the ascending [sorted] series of a life.
LifeRank lifeRank(List<double> sorted, double value) {
  final n = sorted.length;
  if (n == 0) return const LifeRank(0.5, 0.2);
  final below = _lowerBound(sorted, value);
  final upTo = _upperBound(sorted, value);
  final equal = upTo - below;
  if (equal == 0) {
    // Value not in the series (event moment between samples): treat as one more distinct day.
    final u = (below + 0.5) / (n + 1);
    return LifeRank(u, below >= 0.8 * (n + 1) ? 1 : 0);
  }
  final u = (below + equal / 2) / n;
  // Positions below … upTo − 1 (0-based); those at or above 0.8 n are in the top 20 %.
  final cut = (0.8 * n).ceil();
  final inTop = (upTo - math.max(below, cut)).clamp(0, equal);
  return LifeRank(u, inTop / equal);
}

/// Reference ranks of a life: the rank of every [step]-th day of [series], the pool a
/// randomly chosen day of the same life is drawn from.
List<LifeRank> lifePool(List<double> series, {int maxSize = 1500}) {
  if (series.isEmpty) return const [];
  final sorted = [...series]..sort();
  final step = math.max(1, (series.length / maxSize).ceil());
  return [for (var i = 0; i < series.length; i += step) lifeRank(sorted, series[i])];
}

/// One known event day with the reference pool of its person's life.
class EventDaySample {
  final LifeRank rank;
  final List<LifeRank> pool;
  const EventDaySample(this.rank, this.pool);
}

/// Catalog-wide check: do the known event days sit higher in their life's tension than
/// random days of the same lives would?
class EventDaySummary {
  final int events;

  /// Mean percentile of the event days (50 expected).
  final double meanPercentile;

  /// Share of event days in the top 20 % of their life (0…1), and its expectation (0.2 up to
  /// the tie handling of the reference pools).
  final double top20Share;
  final double top20Expected;

  /// Randomization test: each event day replaced by a random day of the same life.
  /// Share of [resamples] with a mean at least as high / as low as observed.
  final double pHigh;
  final double pLow;

  /// Same for the top-20 % share (one-sided, "more event days in the top 20 %").
  final double pTop20;
  final int resamples;

  const EventDaySummary({
    required this.events,
    required this.meanPercentile,
    required this.top20Share,
    required this.top20Expected,
    required this.pHigh,
    required this.pLow,
    required this.pTop20,
    required this.resamples,
  });

  /// Two-sided p-value of the mean percentile.
  double get p => math.min(1.0, 2 * math.min(pHigh, pLow));

  /// Effect size in percentile points above the random expectation.
  double get effect => meanPercentile - 50;

  /// Conventional 5 % level, two-sided; anything else reads as "no relation shown".
  bool get related => p < 0.05;
}

/// Summary of [samples]; null when there is nothing to compare.
EventDaySummary? summarizeEventDays(List<EventDaySample> samples, {int resamples = 10000, math.Random? random}) {
  final s = samples.where((x) => x.pool.isNotEmpty).toList();
  if (s.isEmpty) return null;
  final n = s.length;
  final obsU = s.fold(0.0, (a, x) => a + x.rank.u) / n;
  final obsTop = s.fold(0.0, (a, x) => a + x.rank.top20) / n;
  final expTop = s.fold(0.0, (a, x) => a + x.pool.fold(0.0, (b, r) => b + r.top20) / x.pool.length) / n;
  final rnd = random ?? math.Random(20261120);
  const eps = 1e-12;
  var ge = 0, le = 0, geTop = 0;
  for (var r = 0; r < resamples; r++) {
    var su = 0.0, st = 0.0;
    for (final x in s) {
      final d = x.pool[rnd.nextInt(x.pool.length)];
      su += d.u;
      st += d.top20;
    }
    su /= n;
    st /= n;
    if (su >= obsU - eps) ge++;
    if (su <= obsU + eps) le++;
    if (st >= obsTop - eps) geTop++;
  }
  double p(int k) => (k + 1) / (resamples + 1);
  return EventDaySummary(
    events: n,
    meanPercentile: 100 * obsU,
    top20Share: obsTop,
    top20Expected: expTop,
    pHigh: p(ge),
    pLow: p(le),
    pTop20: p(geTop),
    resamples: resamples,
  );
}
