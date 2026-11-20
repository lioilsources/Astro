import 'dart:math' as math;

import 'package:astro_core/journal.dart';
import 'package:test/test.dart';

/// Synthetic lives: [people] series of [days] tensions with many zero days (ties), as real
/// tension series have.
List<List<double>> _lives(math.Random r, {int people = 60, int days = 6000}) => [
      for (var p = 0; p < people; p++)
        [for (var d = 0; d < days; d++) r.nextDouble() < 0.3 ? 0.0 : (r.nextDouble() * 200).roundToDouble()]
    ];

List<EventDaySample> _samples(List<List<double>> lives, int perPerson, int Function(List<double> life, math.Random r) pick, math.Random r) => [
      for (final life in lives)
        for (var k = 0; k < perPerson; k++)
          () {
            final sorted = [...life]..sort();
            return EventDaySample(lifeRank(sorted, life[pick(life, r)]), lifePool(life));
          }()
    ];

void main() {
  group('lifeRank', () {
    test('mid-rank with ties and top-20 share', () {
      final s = [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0];
      final zero = lifeRank(s, 0);
      expect(zero.u, closeTo(0.25, 1e-12));
      expect(zero.top20, 0);
      expect(lifeRank(s, 5).u, closeTo(0.95, 1e-12));
      expect(lifeRank(s, 5).top20, 1);
      expect(lifeRank(s, 4).top20, 1); // position 8 of 10
      expect(lifeRank(s, 3).top20, 0); // position 7
      // A tie block straddling the 80 % cut: positions 6…9, cut at 8 → half in the top 20 %.
      final t = [0.0, 1, 2, 3, 4, 5, 7, 7, 7, 7].map((v) => v.toDouble()).toList();
      expect(lifeRank(t, 7).top20, closeTo(0.5, 1e-12));
    });

    test('expectation over all days of a life is 0.5 and 0.2', () {
      final r = math.Random(1);
      final life = _lives(r, people: 1, days: 5000).single;
      final sorted = [...life]..sort();
      final ranks = [for (final v in life) lifeRank(sorted, v)];
      expect(ranks.fold(0.0, (a, x) => a + x.u) / ranks.length, closeTo(0.5, 1e-9));
      expect(ranks.fold(0.0, (a, x) => a + x.top20) / ranks.length, closeTo(0.2, 1e-9));
    });
  });

  group('summarizeEventDays', () {
    test('events on random days of their lives show no relation', () {
      final r = math.Random(42);
      final lives = _lives(r);
      final s = _samples(lives, 4, (life, r) => r.nextInt(life.length), r);
      final sum = summarizeEventDays(s, resamples: 4000, random: math.Random(7))!;
      expect(sum.events, 240);
      expect(sum.related, isFalse);
      expect(sum.meanPercentile, closeTo(50, 4));
      expect(sum.top20Share, closeTo(0.2, 0.06));
      expect(sum.p, greaterThan(0.05));
    });

    test('deterministic for a fixed seed', () {
      final lives = _lives(math.Random(3), people: 20, days: 2000);
      final s = _samples(lives, 3, (life, r) => r.nextInt(life.length), math.Random(4));
      final a = summarizeEventDays(s, resamples: 2000, random: math.Random(9))!;
      final b = summarizeEventDays(s, resamples: 2000, random: math.Random(9))!;
      expect(a.pHigh, b.pHigh);
      expect(a.pTop20, b.pTop20);
      expect(a.meanPercentile, b.meanPercentile);
    });

    test('events placed on the tensest days are detected', () {
      final r = math.Random(5);
      final lives = _lives(r, people: 30, days: 3000);
      int tensest(List<double> life, math.Random r) {
        final idx = List<int>.generate(life.length, (i) => i)..sort((a, b) => life[b].compareTo(life[a]));
        return idx[r.nextInt(life.length ~/ 10)];
      }

      final sum = summarizeEventDays(_samples(lives, 2, tensest, r), resamples: 4000, random: math.Random(6))!;
      expect(sum.related, isTrue);
      expect(sum.effect, greaterThan(30));
      expect(sum.top20Share, greaterThan(0.9));
      expect(sum.pTop20, lessThan(0.01));
    });

    test('empty input gives null', () {
      expect(summarizeEventDays(const []), isNull);
    });
  });
}
