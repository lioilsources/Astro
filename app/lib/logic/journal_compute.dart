import 'dart:isolate';
import 'dart:math' as math;

import 'package:astro_core/astro_core.dart';
import 'package:astro_core/journal.dart';

/// Everything the journal screen shows from the statistics (plan 10.3).
class JournalReport {
  final JournalEvaluation evaluation;
  final List<HypothesisResult> hypotheses;

  /// Catalog persons available for the foreign-chart control.
  final int catalogSize;
  const JournalReport(this.evaluation, this.hypotheses, this.catalogSize);
}

/// Seed derived from the data: the same journal always gives the same numbers.
int journalSeed(Journal j) => Object.hashAll([for (final r in j.evaluated) r.id]) & 0x7fffffff;

/// Runs the whole evaluation in an isolate. [catalog] are birth data of catalog
/// persons (the profile itself excluded); 20 of them are drawn at random.
Future<JournalReport> computeJournalReport(Chart natal, Journal journal, List<BirthData> catalog, {int? seed}) {
  final s = seed ?? journalSeed(journal);
  return Isolate.run(() {
    final picked = pickRandom(catalog, controlPersons, math.Random(s));
    final controls = [for (final b in picked) Chart.compute(b)];
    final eval = evaluateJournal(natal, journal, controls, seed: s);
    final evaluated = journal.evaluated;
    final hyps = [
      for (final h in journal.hypotheses)
        evaluateHypothesis(h, evaluated, hypothesisActiveDays(natal, h, [for (final d in evaluated) if (d.dayNumber > parseDayKey(h.createdDay)) d])),
    ];
    return JournalReport(eval, hyps, catalog.length);
  });
}
