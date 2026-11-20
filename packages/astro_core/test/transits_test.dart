import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

final natal = Chart.compute(const BirthData(
  moment: LocalMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, basis: TimeBasis.ut),
  lat: 50.0833,
  lon: 14.4167,
));

double jd(int y, int m, int d, [double h = 0]) => julianDay(y, m, d, h);

void main() {
  final engine = TransitEngine(natal);

  test('November 2026 matches the old Astromat calendar', () {
    final ev = engine.events(jd(2026, 11, 1), jd(2026, 12, 1), bodies: [Body.sun]);
    final sextileSun = ev.firstWhere((e) => e.type == AspectType.sextile && e.target == const ChartPoint.body(Body.sun));
    expect(sextileSun.exacts.single, inInclusiveRange(jd(2026, 11, 1), jd(2026, 11, 6)));
    final squareMars = ev.firstWhere((e) => e.type == AspectType.square && e.target == const ChartPoint.body(Body.mars));
    expect(squareMars.exacts.single, inInclusiveRange(jd(2026, 11, 19), jd(2026, 11, 24)));
    expect(squareMars.end - squareMars.start, closeTo(2, 0.3)); // 1° orb, ~1°/day
  });

  test('slow planets: three passes in a series and stations in orb', () {
    final ev = engine.events(jd(2020, 1, 1), jd(2030, 1, 1), bodies: [Body.jupiter, Body.saturn, Body.uranus]);
    final third = ev.where((e) => e.passNumbers.contains(3) && e.passTotal != null).toList();
    expect(third, isNotEmpty);
    final e = third.first;
    expect(e.passTotal, greaterThanOrEqualTo(3));
    final series = ev.where((x) => x.transiting == e.transiting && x.target == e.target && x.type == e.type && x.side == e.side).toList();
    expect([for (final s in series) ...s.passNumbers], containsAllInOrder([1, 2, 3]));
    expect(ev.any((x) => x.station != null), isTrue);
  });

  test('Moon aspects last hours and phases change at the exact moment', () {
    final ev = engine.events(jd(2026, 11, 19), jd(2026, 11, 20), bodies: [Body.moon]);
    expect(ev, isNotEmpty);
    for (final e in ev.where((e) => e.exacts.isNotEmpty)) {
      final hours = (e.end - e.start) * 24;
      expect(hours, inInclusiveRange(1, 8));
      final ex = e.exacts.single;
      expect(engine.phaseAt(e, e.start + 1 / 1440), TransitPhase.approaching);
      expect(engine.phaseAt(e, ex), TransitPhase.exact);
      expect(engine.phaseAt(e, e.end - 1 / 1440), TransitPhase.separating);
      expect(engine.deviationAt(e, ex).abs(), lessThan(0.001));
    }
  });

  test('strength is 0–100, tighter is stronger, slow is stronger', () {
    final ev = engine.events(jd(2026, 11, 1), jd(2026, 12, 1));
    for (final e in ev) {
      final ex = e.nearestExact((e.start + e.end) / 2) ?? (e.start + e.end) / 2;
      final s = engine.strengthAt(e, ex);
      expect(s, inInclusiveRange(0, 100));
      expect(s, greaterThanOrEqualTo(engine.strengthAt(e, e.start)));
    }
  });

  test('house ingresses cross natal cusps', () {
    final ing = engine.ingresses(jd(2026, 11, 1), jd(2026, 12, 1), bodies: [Body.sun, Body.moon]);
    expect(ing.where((i) => i.body == Body.moon).length, greaterThanOrEqualTo(10));
    for (final i in ing) {
      final cusp = natal.houses!.cusps![i.house - 1];
      expect(angDist(Ephemeris.longitude(i.body, i.jd), cusp), lessThan(0.05));
    }
  });

  test('tension score is deterministic and the sampled series matches direct values', () {
    expect(engine.tensionAt(jd(2026, 11, 21)), engine.tensionAt(jd(2026, 11, 21)));
    final from = jd(2026, 1, 1, 12);
    final series = engine.tensionSeries(from, 60);
    for (var d = 0; d < 60; d += 7) {
      expect(series[d], closeTo(engine.tensionAt(from + d), 6), reason: 'day $d');
    }
  });

  test('tension profile equals the series, with own or shared tracks', () {
    final from = jd(2020, 1, 1, 12);
    const days = 800;
    final series = engine.tensionSeries(from, days);
    final moment = from + 123.3;
    final own = engine.tensionProfile(from, days, [moment]);
    for (var d = 0; d < days; d++) {
      expect(own.series[d], closeTo(series[d], 1e-9), reason: 'day $d');
    }
    expect(own.at.single, closeTo(engine.tensionAt(moment), 6));
    final shared = {
      for (final b in Body.planets)
        if (b != Body.moon) b: TransitEngine.tensionTrack(b, from - 400, from + days + 400),
    };
    // A track built in pieces on one grid and joined equals one long build.
    for (final b in [Body.sun, Body.mercury, Body.mars]) {
      final step = TransitEngine.tensionStepDays(b);
      final piece = step * 50;
      final whole = TransitEngine.tensionTrack(b, from, from + days);
      final joined = LongitudeTrack.joined([
        for (var a = from; a < from + days; a += piece) LongitudeTrack.build(b, a, (a + piece).clamp(from, from + days), step),
      ]);
      for (var t = from; t < from + days; t += 7.3) {
        expect(joined.at(t), closeTo(whole.at(t), 1e-9), reason: '$b $t');
      }
    }
    final viaShared = engine.tensionProfile(from, days, [moment], shared: shared);
    for (var d = 0; d < days; d += 13) {
      expect(viaShared.series[d], closeTo(series[d], 0.5), reason: 'day $d');
    }
  });
}
