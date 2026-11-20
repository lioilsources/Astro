import 'dart:math' as math;

import 'package:astro_core/astro_core.dart';
import 'package:astro_core/journal.dart';
import 'package:test/test.dart';

Chart chartOf(int y, int m, int d, double lat, double lon) => Chart.compute(BirthData(
      moment: LocalMoment(year: y, month: m, day: d, hour: 12, minute: 0, basis: TimeBasis.ut),
      lat: lat,
      lon: lon,
    ));

final natal = chartOf(2000, 1, 1, 50.0833, 14.4167);

/// Rated days starting 2026-01-01 (noon UT), with ratings from [rate].
Journal synthetic(int days, int Function(int i, double tension) rate, {bool saw = true, Set<String> Function(int i)? tags}) {
  final engine = TransitEngine(natal);
  final start = dayNumber(2026, 1, 1);
  return Journal(ratings: [
    for (var i = 0; i < days; i++)
      () {
        final day = dayKeyOf(start + i);
        final jd = julianDay(2026, 1, 1, 12) + i;
        final t = engine.tensionAt(jd);
        return DayRating(
          id: 'r$i',
          day: day,
          createdAt: DateTime.utc(2026, 1, 1, 20).add(Duration(days: i)),
          rating: rate(i, t),
          tags: (tags?.call(i) ?? const <String>{}).toList(),
          jd: jd,
          tension: t,
          sawPrediction: saw,
        );
      }()
  ]);
}

DayRating rating(String id, String day, {int value = 0, String? corrects}) =>
    DayRating(id: id, day: day, createdAt: DateTime.utc(2026), rating: value, jd: 0, tension: 0, corrects: corrects);

void main() {
  group('append-only log', () {
    final j0 = Journal();

    test('a day is open from its start until the end of the following day', () {
      final j = j0.append(rating('a', '2026-03-10'), DateTime(2026, 3, 10, 21));
      expect(j.append(rating('b', '2026-03-10', value: 1), DateTime(2026, 3, 11, 23, 59)).log.original('2026-03-10')!.id, 'b');
      expect(() => j.append(rating('c', '2026-03-10'), DateTime(2026, 3, 12, 0, 1)), throwsA(isA<LogRuleError>()));
      expect(() => j0.append(rating('f', '2026-03-11'), DateTime(2026, 3, 10, 23)), throwsA(isA<LogRuleError>()), reason: 'future day');
    });

    test('superseded originals stay in the log', () {
      final j = j0
          .append(rating('a', '2026-03-10', value: -1), DateTime(2026, 3, 10, 21))
          .append(rating('b', '2026-03-10', value: 2), DateTime(2026, 3, 11, 8));
      expect(j.log.history('2026-03-10').map((r) => r.id), ['a', 'b']);
      expect(j.evaluated.single.rating, 2);
    });

    test('a closed day only takes a correction of its final original, which is not evaluated', () {
      final j = j0.append(rating('a', '2026-03-10', value: -2), DateTime(2026, 3, 10, 21));
      final late = DateTime(2026, 3, 20);
      expect(() => j.append(rating('c', '2026-03-10', corrects: 'a'), DateTime(2026, 3, 11)), throwsA(isA<LogRuleError>()), reason: 'still open');
      expect(() => j.append(rating('c', '2026-03-11', corrects: 'a'), late), throwsA(isA<LogRuleError>()), reason: 'other day');
      expect(() => j.append(rating('c', '2026-03-10', corrects: 'zz'), late), throwsA(isA<LogRuleError>()));
      final fixed = j.append(rating('c', '2026-03-10', value: 1, corrects: 'a'), late);
      expect(fixed.log.current('2026-03-10')!.id, 'c');
      expect(fixed.log.corrections('2026-03-10').single.id, 'c');
      expect(fixed.evaluated.single.rating, -2);
      expect(() => fixed.append(rating('d', '2026-03-10', corrects: 'c'), late), throwsA(isA<LogRuleError>()), reason: 'correct the original');
      expect(() => fixed.append(rating('a', '2026-03-12'), DateTime(2026, 3, 12)), throwsA(isA<LogRuleError>()), reason: 'duplicate id');
    });

    test('rating outside −2…+2 is refused', () {
      expect(() => rating('x', '2026-01-01', value: 3), throwsRangeError);
    });
  });

  group('storage', () {
    test('round trip keeps every record, hypothesis and blind test', () {
      final j = Journal(
        ratings: [rating('a', '2026-03-10', value: 1), rating('b', '2026-03-10', corrects: 'a')],
        hypotheses: [
          const Hypothesis(id: 'h', createdDay: '2026-03-01', transiting: Body.mars, type: AspectType.square, target: ChartPoint.body(Body.moon), tag: 'anxiety'),
          const Hypothesis(id: 'g', createdDay: '2026-03-01', transiting: Body.saturn, type: AspectType.conjunction, target: ChartPoint.angle(Angle.asc), tag: 'order'),
        ],
        blindTests: [const BlindTest('2026-03-01', stoppedDay: '2026-04-01')],
      );
      final back = Journal.fromJson(j.toJson());
      expect(back.toJson(), j.toJson());
      expect(back.hypotheses.last.target, const ChartPoint.angle(Angle.asc));
    });

    test('older records without versions migrate to "unknown" and get recomputed', () {
      final j = Journal.fromJson({
        'ratings': [
          {'id': 'a', 'day': '2026-03-10', 'created': '2026-03-10T20:00:00.000Z', 'rating': -1, 'jd': 2461110.0, 'tension': 999.0}
        ],
      });
      final r = j.ratings.single;
      expect(r.engineVersion, 'unknown');
      expect(r.formulaVersion, 0);
      expect(r.sawPrediction, isTrue);
      final engine = TransitEngine(natal);
      expect(tensionOf(r, engine), engine.tensionAt(2461110.0));
    });

    test('a newer schema is refused instead of being overwritten', () {
      expect(() => Journal.fromJson({'schema': journalSchema + 1}), throwsA(isA<JournalSchemaError>()));
    });

    test('CSV export quotes notes and lists corrections', () {
      final j = Journal(ratings: [
        DayRating(id: 'a', day: '2026-03-10', createdAt: DateTime.utc(2026, 3, 10, 20), rating: -1, note: 'špatně, "hodně"', tags: ['anxiety', 'fatigue'], jd: 1, tension: 12.345),
        rating('b', '2026-03-10', corrects: 'a'),
      ]);
      final lines = journalCsv(j).trim().split('\n');
      expect(lines.first, startsWith('id,day,created_utc,rating'));
      expect(lines[1], contains('"špatně, ""hodně"""'));
      expect(lines[1], contains('anxiety fatigue'));
      expect(lines[1], contains('12.35'));
      expect(lines[2], endsWith(',a'));
    });
  });

  group('blind test', () {
    test('runs 90 days and locks transits until today is rated', () {
      final now = DateTime(2026, 3, 10, 9);
      var j = Journal().startBlind(now);
      expect(j.transitsLocked(now), isTrue);
      expect(j.isBlindRating('2026-03-10', now), isTrue);
      j = j.append(rating('a', '2026-03-10'), now);
      expect(j.transitsLocked(now), isFalse);
      // Yesterday rated after today unlocked the view: saw the prediction.
      expect(j.isBlindRating('2026-03-09', now), isFalse);
      expect(j.blindOn(dayNumber(2026, 6, 7)), isNotNull);
      expect(j.blindOn(dayNumber(2026, 6, 8)), isNull);
      final stopped = j.stopBlind(DateTime(2026, 3, 20));
      expect(stopped.transitsLocked(DateTime(2026, 3, 20)), isFalse);
      expect(stopped.isBlindRating('2026-03-20', DateTime(2026, 3, 20)), isFalse);
    });

    test('blind and seen ratings are evaluated apart', () {
      final j = synthetic(70, (i, t) => i % 5 - 2, saw: false);
      final e = evaluateJournal(natal, j, const [], seed: 1, permutations: 200);
      expect(e.blind.result.n, 70);
      expect(e.seen.result.relation, Relation.tooFew);
    });
  });

  group('statistics', () {
    test('ranks average ties and Spearman matches a hand value', () {
      expect(ranks([10, 20, 20, 5]), [2, 3.5, 3.5, 1]);
      expect(spearman([1, 2, 3, 4, 5], [5, 6, 7, 8, 7]), closeTo(0.8208, 1e-4));
      expect(spearman([1, 1, 1], [1, 2, 3]), isNull);
    });

    test('Fisher exact test', () {
      // 3 of 3 tagged on transit days, 0 of 3 otherwise: p = 1/20.
      expect(fisherGreater(3, 3, 3, 6), closeTo(0.05, 1e-9));
      expect(fisherGreater(0, 3, 3, 6), closeTo(1, 1e-9));
    });

    test('same seed, same result', () {
      final j = synthetic(80, (i, t) => (i * 7) % 5 - 2);
      final a = evaluateJournal(natal, j, const [], seed: 42, permutations: 2000);
      final b = evaluateJournal(natal, j, const [], seed: 42, permutations: 2000);
      expect(a.seen.result.p, b.seen.result.p);
    });

    test('fewer than 60 days: too little data', () {
      final e = evaluateJournal(natal, synthetic(59, (i, t) => 0), const []);
      expect(e.seen.result.relation, Relation.tooFew);
      expect(e.seen.control, isNull);
    });
  });

  group('synthetic journals (plan 10.3)', () {
    final controls = [
      chartOf(1950, 5, 3, 48.2, 16.4),
      chartOf(1971, 9, 21, 40.4, -3.7),
      chartOf(1983, 2, 14, -33.9, 151.2),
      chartOf(1964, 11, 30, 35.7, 139.7),
      chartOf(1990, 7, 7, 51.5, -0.1),
      chartOf(1938, 12, 24, 55.8, 37.6),
    ];

    test('random ratings do not come out as a relation', () {
      var flagged = 0;
      for (var seed = 0; seed < 20; seed++) {
        final rnd = math.Random(seed);
        final j = synthetic(120, (i, t) => rnd.nextInt(5) - 2);
        final e = evaluateJournal(natal, j, const [], seed: seed, permutations: 2000);
        expect(e.seen.result.relation, isNot(Relation.tooFew));
        if (e.seen.result.relation == Relation.expected) flagged++;
      }
      // 5 % false alarms expected; allow some slack, never a systematic hit.
      expect(flagged, lessThanOrEqualTo(3));

      final rnd = math.Random(2026);
      final one = evaluateJournal(natal, synthetic(120, (i, t) => rnd.nextInt(5) - 2), controls, seed: 7);
      expect(one.seen.result.relation, Relation.none);
      expect(one.seen.result.test!.permutations, defaultPermutations);
    });

    test('ratings derived from the score do come out, and beat foreign charts', () {
      final rnd = math.Random(5);
      // Worse days when tension is above its usual level (~115 here), with noise.
      final j = synthetic(120, (i, t) => ((t > 115 ? -1 : 1) + rnd.nextInt(3) - 1).clamp(-2, 2));
      final e = evaluateJournal(natal, j, controls, seed: 3);
      final r = e.seen.result;
      expect(r.relation, Relation.expected);
      expect(r.rho, lessThan(-0.3));
      expect(r.p, lessThan(0.01));
      expect(e.seen.control!.persons, controls.length);
      expect(e.seen.control!.asGoodOrBetter, 0);
    });

    test('a hypothesis counts only days after it was written and compares with the base rate', () {
      const h = Hypothesis(id: 'h', createdDay: '2026-01-31', transiting: Body.sun, type: AspectType.conjunction, target: ChartPoint.body(Body.sun), tag: 'joy');
      // Transit Sun conjunct natal Sun (~10° Capricorn): around 31 Dec – 1 Jan, out of the range.
      // Use the Moon instead: frequent, so both groups fill up.
      const hm = Hypothesis(id: 'm', createdDay: '2026-01-31', transiting: Body.moon, type: AspectType.square, target: ChartPoint.body(Body.sun), tag: 'anxiety');
      final engine = TransitEngine(natal);
      final base = synthetic(180, (i, t) => 0);
      final active = hypothesisActiveDays(natal, hm, base.evaluated);
      expect(active, isNotEmpty);
      // Tag exactly the active days: perfect hit.
      final start = dayNumber(2026, 1, 1);
      final j = synthetic(180, (i, t) => 0, tags: (i) => active.contains(dayKeyOf(start + i)) ? {'anxiety'} : {});
      final r = evaluateHypothesis(hm, j.evaluated, active);
      expect(r.transitDays + r.otherDays, 180 - 31);
      expect(r.transitRate, 1);
      expect(r.baseRate, 0);
      expect(r.holds, isTrue);
      // Tag on no day: nothing holds.
      final none = evaluateHypothesis(hm, base.evaluated, active);
      expect(none.holds, isFalse);
      expect(evaluateHypothesis(h, base.evaluated, hypothesisActiveDays(natal, h, base.evaluated)).transitDays, 0);
      expect(engine.natal, natal);
    });
  });
}
