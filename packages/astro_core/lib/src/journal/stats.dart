import 'dart:math' as math;

/// Ranks 1…n, ties get the average rank.
List<double> ranks(List<num> xs) {
  final idx = List<int>.generate(xs.length, (i) => i)..sort((a, b) => xs[a].compareTo(xs[b]));
  final out = List<double>.filled(xs.length, 0);
  var i = 0;
  while (i < idx.length) {
    var j = i;
    while (j + 1 < idx.length && xs[idx[j + 1]] == xs[idx[i]]) {
      j++;
    }
    final r = (i + j) / 2 + 1;
    for (var k = i; k <= j; k++) {
      out[idx[k]] = r;
    }
    i = j + 1;
  }
  return out;
}

double? _pearson(List<double> a, List<double> b) {
  final n = a.length;
  if (n < 2) return null;
  final ma = a.reduce((x, y) => x + y) / n, mb = b.reduce((x, y) => x + y) / n;
  var sab = 0.0, saa = 0.0, sbb = 0.0;
  for (var i = 0; i < n; i++) {
    final da = a[i] - ma, db = b[i] - mb;
    sab += da * db;
    saa += da * da;
    sbb += db * db;
  }
  if (saa == 0 || sbb == 0) return null;
  return sab / math.sqrt(saa * sbb);
}

/// Spearman rank correlation; null when one side is constant.
double? spearman(List<num> x, List<num> y) {
  if (x.length != y.length) throw ArgumentError('length mismatch');
  return _pearson(ranks(x), ranks(y));
}

/// Result of [blockPermutationTest].
class PermutationResult {
  final double rho;

  /// Share of shuffles with rho ≤ observed (as good or better a fit for "tension → worse day").
  final double pNegative;

  /// Share of shuffles with rho ≥ observed.
  final double pPositive;
  final int permutations;
  final int blocks;
  const PermutationResult(this.rho, this.pNegative, this.pPositive, this.permutations, this.blocks);
}

/// Permutation test of Spearman's rho that shuffles whole blocks (weeks) of [y]
/// against fixed [x]. [block] gives the block of each observation; blocks keep
/// their internal order and are laid back into the observation slots in order.
/// Returns null when rho is undefined (a constant side).
PermutationResult? blockPermutationTest(
  List<num> x,
  List<num> y,
  List<int> block, {
  int permutations = 10000,
  math.Random? random,
}) {
  final n = x.length;
  if (y.length != n || block.length != n) throw ArgumentError('length mismatch');
  final rx = ranks(x), ry = ranks(y);
  final observed = _pearson(rx, ry);
  if (observed == null) return null;

  // Pearson of ranks with fixed marginals: only the cross product changes.
  final mx = rx.reduce((a, b) => a + b) / n, my = ry.reduce((a, b) => a + b) / n;
  final cx = [for (final v in rx) v - mx], cy = [for (final v in ry) v - my];
  final norm = math.sqrt(cx.fold(0.0, (s, v) => s + v * v) * cy.fold(0.0, (s, v) => s + v * v));

  final groups = <int, List<double>>{};
  for (var i = 0; i < n; i++) {
    groups.putIfAbsent(block[i], () => []).add(cy[i]);
  }
  final blocks = groups.values.toList();
  final order = List<int>.generate(blocks.length, (i) => i);
  final rnd = random ?? math.Random();
  const eps = 1e-12;
  var le = 0, ge = 0;
  final perm = List<double>.filled(n, 0);
  for (var p = 0; p < permutations; p++) {
    for (var i = order.length - 1; i > 0; i--) {
      final j = rnd.nextInt(i + 1);
      final t = order[i];
      order[i] = order[j];
      order[j] = t;
    }
    var k = 0;
    for (final b in order) {
      for (final v in blocks[b]) {
        perm[k++] = v;
      }
    }
    var s = 0.0;
    for (var i = 0; i < n; i++) {
      s += cx[i] * perm[i];
    }
    final rho = s / norm;
    if (rho <= observed + eps) le++;
    if (rho >= observed - eps) ge++;
  }
  return PermutationResult(observed, le / permutations, ge / permutations, permutations, blocks.length);
}

double _logChoose(int n, int k) => _lgammaInt(n) - _lgammaInt(k) - _lgammaInt(n - k);

/// log(n!) by summation (n stays in the hundreds here).
double _lgammaInt(int n) {
  var s = 0.0;
  for (var i = 2; i <= n; i++) {
    s += math.log(i);
  }
  return s;
}

/// One-sided Fisher exact test: probability of at least [a] tagged days among
/// [n1] transit days when [k] of all [n] days are tagged.
double fisherGreater(int a, int n1, int k, int n) {
  var p = 0.0;
  final denom = _logChoose(n, n1);
  for (var x = a; x <= math.min(n1, k); x++) {
    if (n1 - x > n - k) continue;
    p += math.exp(_logChoose(k, x) + _logChoose(n - k, n1 - x) - denom);
  }
  return p.clamp(0.0, 1.0);
}
