import 'dart:math' as math;

import '../chart.dart';
import '../transits.dart';
import '../version.dart';
import 'journal.dart';
import 'log.dart';
import 'stats.dart';

/// Below this many rated days the app says "too little data" (plan 10.3).
const minEvaluatedDays = 60;
const defaultPermutations = 10000;
const controlPersons = 20;

/// The foreign-chart control needs at least this many catalog persons.
const minControlPersons = 5;

/// A transit-days or other-days group of a hypothesis needs at least this many days.
const minHypothesisDays = 5;
const significance = 0.05;

enum Relation {
  /// Fewer than [minEvaluatedDays] rated days.
  tooFew,

  /// Tension and rating do not vary both (e.g. every rating the same).
  undefined,

  /// Higher tension goes with worse days — what the astrological reading predicts.
  expected,

  /// Higher tension goes with better days.
  opposite,

  /// No relation beyond what reshuffled weeks give.
  none,
}

/// Verbal size of Spearman's rho (Cohen's conventional thresholds).
enum EffectSize { negligible, small, moderate, large }

EffectSize effectSizeOf(double rho) {
  final a = rho.abs();
  if (a < 0.1) return EffectSize.negligible;
  if (a < 0.3) return EffectSize.small;
  if (a < 0.5) return EffectSize.moderate;
  return EffectSize.large;
}

class CorrelationResult {
  final int n;
  final PermutationResult? test;
  final Relation relation;
  const CorrelationResult(this.n, this.test, this.relation);

  double? get rho => test?.rho;
  EffectSize? get size => test == null ? null : effectSizeOf(test!.rho);

  /// p-value in the direction the data lean to.
  double? get p => test == null ? null : (test!.rho <= 0 ? test!.pNegative : test!.pPositive);
}

/// Rank correlation of [tension] and [ratings] on days [dayNumbers], tested by
/// shuffling whole weeks [permutations]×.
CorrelationResult correlate(
  List<int> dayNumbers,
  List<double> tension,
  List<int> ratings, {
  int permutations = defaultPermutations,
  math.Random? random,
}) {
  final n = dayNumbers.length;
  if (n < minEvaluatedDays) return CorrelationResult(n, null, Relation.tooFew);
  final first = dayNumbers.reduce(math.min);
  final weeks = [for (final d in dayNumbers) (d - first) ~/ 7];
  final t = blockPermutationTest(tension, ratings, weeks, permutations: permutations, random: random);
  if (t == null) return CorrelationResult(n, null, Relation.undefined);
  final rel = t.pNegative <= significance
      ? Relation.expected
      : t.pPositive <= significance
          ? Relation.opposite
          : Relation.none;
  return CorrelationResult(n, t, rel);
}

/// Own chart against the transits of foreign charts on the same days.
class ControlResult {
  /// Foreign charts used.
  final int persons;
  final double ownRho;
  final List<double> rhos;

  /// Foreign charts that fit as well or better (rho ≤ own).
  final int asGoodOrBetter;
  const ControlResult(this.persons, this.ownRho, this.rhos, this.asGoodOrBetter);

  bool get enough => persons >= minControlPersons;

  /// At most 5 % of foreign charts fit as well (with 20 persons: none or one).
  bool get ownFitsBetter => enough && asGoodOrBetter <= persons * significance;
  double get median {
    if (rhos.isEmpty) return 0;
    final s = [...rhos]..sort();
    final m = s.length ~/ 2;
    return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2;
  }
}

ControlResult controlCheck(double ownRho, List<int> ratings, List<List<double>> foreignTension) {
  final rhos = <double>[];
  for (final t in foreignTension) {
    final r = spearman(t, ratings);
    // A constant foreign series cannot fit: count it as no relation.
    rhos.add(r ?? 0);
  }
  return ControlResult(foreignTension.length, ownRho, rhos, rhos.where((r) => r <= ownRho + 1e-12).length);
}

/// Picks up to [count] items at random without repetition.
List<T> pickRandom<T>(List<T> pool, int count, math.Random random) {
  final copy = [...pool]..shuffle(random);
  return copy.take(count).toList();
}

class GroupEvaluation {
  final CorrelationResult result;

  /// Null below [minEvaluatedDays] or without a defined rho; check [ControlResult.enough].
  final ControlResult? control;
  const GroupEvaluation(this.result, this.control);
}

/// Blind ratings and ratings made after seeing the forecast are evaluated apart.
class JournalEvaluation {
  final GroupEvaluation blind;
  final GroupEvaluation seen;
  const JournalEvaluation(this.blind, this.seen);
}

/// Tension of a stored rating; recomputed when the formula changed since.
double tensionOf(DayRating r, TransitEngine engine) =>
    r.formulaVersion == tensionFormulaVersion ? r.tension : engine.tensionAt(r.jd);

/// Full evaluation (plan 10.3). Heavy: run in an isolate.
/// [controls] are foreign charts (already picked at random); [seed] makes the shuffles repeatable.
JournalEvaluation evaluateJournal(Chart natal, Journal journal, List<Chart> controls, {int? seed, int permutations = defaultPermutations}) {
  final engine = TransitEngine(natal);
  final random = math.Random(seed);
  final foreign = [for (final c in controls) TransitEngine(c)];
  GroupEvaluation group(List<DayRating> days) {
    final ratings = [for (final r in days) r.rating];
    final result = correlate(
      [for (final r in days) r.dayNumber],
      [for (final r in days) tensionOf(r, engine)],
      ratings,
      permutations: permutations,
      random: random,
    );
    final rho = result.rho;
    if (rho == null) return GroupEvaluation(result, null);
    final ft = [
      for (final e in foreign) [for (final r in days) e.tensionAt(r.jd)]
    ];
    return GroupEvaluation(result, controlCheck(rho, ratings, ft));
  }

  final all = journal.evaluated;
  return JournalEvaluation(
    group([for (final r in all) if (!r.sawPrediction) r]),
    group([for (final r in all) if (r.sawPrediction) r]),
  );
}

class HypothesisResult {
  final Hypothesis hypothesis;
  final int transitDays, transitTagged, otherDays, otherTagged;

  /// One-sided Fisher exact p (tag more frequent on transit days); null without enough days.
  final double? p;
  const HypothesisResult(this.hypothesis, this.transitDays, this.transitTagged, this.otherDays, this.otherTagged, this.p);

  bool get enough => transitDays >= minHypothesisDays && otherDays >= minHypothesisDays;
  double get transitRate => transitDays == 0 ? 0 : transitTagged / transitDays;

  /// Base rate: how often the tag comes without the transit.
  double get baseRate => otherDays == 0 ? 0 : otherTagged / otherDays;
  bool get holds => enough && p! <= significance;
}

/// Days (keys) among [days] when the hypothesis transit is in orb at some time of the local day.
Set<String> hypothesisActiveDays(Chart natal, Hypothesis h, List<DayRating> days) {
  if (days.isEmpty) return const {};
  final from = days.map((d) => d.jd).reduce(math.min) - 0.5, to = days.map((d) => d.jd).reduce(math.max) + 0.5;
  final events = [
    for (final e in TransitEngine(natal).events(from, to, bodies: [h.transiting]))
      if (e.type == h.type && e.target == h.target) e
  ];
  return {
    for (final d in days)
      if (events.any((e) => e.start < d.jd + 0.5 && e.end > d.jd - 0.5)) d.day
  };
}

/// Counts only days after the hypothesis was written down.
HypothesisResult evaluateHypothesis(Hypothesis h, List<DayRating> evaluated, Set<String> activeDays) {
  final after = parseDayKey(h.createdDay);
  final days = [for (final d in evaluated) if (d.dayNumber > after) d];
  var td = 0, tt = 0, od = 0, ot = 0;
  for (final d in days) {
    final tagged = d.tags.contains(h.tag);
    if (activeDays.contains(d.day)) {
      td++;
      if (tagged) tt++;
    } else {
      od++;
      if (tagged) ot++;
    }
  }
  final enough = td >= minHypothesisDays && od >= minHypothesisDays;
  return HypothesisResult(h, td, tt, od, ot, enough ? fisherGreater(tt, td, tt + ot, td + od) : null);
}
