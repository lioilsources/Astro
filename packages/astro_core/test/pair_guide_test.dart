import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:test/test.dart';

Chart chartAt(int year, int month, int day, int? hour, int? minute) => Chart.compute(BirthData(
      moment: LocalMoment(year: year, month: month, day: day, hour: hour, minute: minute, basis: TimeBasis.ut),
      lat: 50.0833,
      lon: 14.4167,
    ));

Aspect asp(Body a, Body b, AspectType t) => Aspect(ChartPoint.body(a), ChartPoint.body(b), t, 1, 8, false);

// Fictional pair from app/test/synastry_test.dart (no real birth data in the repo).
final anna = chartAt(1980, 5, 14, 8, 30);
final petr = chartAt(1983, 11, 2, 19, 5);

TransitSeries series(double start, double end, {Body body = Body.saturn}) =>
    TransitSeries(body, const ChartPoint.body(Body.venus), AspectType.square, 1, start, end, [start + 1], null, const []);

void main() {
  group('tone', () {
    test('conjunction with Saturn strains, Venus–Jupiter and Mars–Venus support', () {
      expect(toneOf(asp(Body.sun, Body.saturn, AspectType.conjunction)), PairTone.straining);
      expect(toneOf(asp(Body.venus, Body.jupiter, AspectType.conjunction)), PairTone.supportive);
      expect(toneOf(asp(Body.mars, Body.venus, AspectType.conjunction)), PairTone.supportive);
      expect(toneOf(asp(Body.mars, Body.moon, AspectType.conjunction)), PairTone.straining);
      expect(toneOf(asp(Body.sun, Body.moon, AspectType.square)), PairTone.straining);
      expect(toneOf(asp(Body.saturn, Body.moon, AspectType.trine)), PairTone.supportive);
    });

    test('areas: one per planet that has one', () {
      expect(areasOf(asp(Body.moon, Body.mercury, AspectType.trine)), {PairArea.feeling, PairArea.talk});
      expect(areasOf(asp(Body.jupiter, Body.pluto, AspectType.trine)), isEmpty);
      expect(areasOf(asp(Body.sun, Body.saturn, AspectType.square)), {PairArea.respect});
    });
  });

  group('guide', () {
    final guide = PairGuide.of(Synastry.compute(anna, petr));

    test('chapters in order, every key known', () {
      expect(guide.chapters.map((c) => c.id), GuideChapterId.values);
      final known = {for (final f in allKeysByFamily().values) ...f};
      for (final c in guide.chapters) {
        expect(known, contains(c.introKey));
        for (final b in c.blocks) {
          expect(known, contains(b.key), reason: b.key);
        }
      }
    });

    test('a full text appears once; other chapters only link to it', () {
      final full = [for (final c in guide.chapters) for (final b in c.blocks) if (!b.linkOnly) b.key];
      expect(full.toSet(), hasLength(full.length));
      final strengths = guide.chapter(GuideChapterId.strengths).blocks.map((b) => b.key).toSet();
      final cautions = guide.chapter(GuideChapterId.cautions).blocks.map((b) => b.key).toSet();
      expect(strengths.intersection(cautions), isEmpty);
      for (final id in [GuideChapterId.talk, GuideChapterId.respect, GuideChapterId.needs]) {
        final links = guide.chapter(id).blocks.where((b) => b.linkOnly).toList();
        expect(links.length, lessThanOrEqualTo(maxGuideLinks));
        for (final l in links) {
          expect(strengths.union(cautions), contains(l.key));
        }
      }
    });

    test('six needs per person with a birth time', () {
      final needs = [for (final c in guide.chapters) for (final b in c.blocks) if (b.need != null) b.need!];
      expect(needs.where((n) => n.ofFirst).map((n) => n.point).toSet(), NeedPoint.values.toSet());
      final both = [for (final c in guide.chapters) for (final b in c.blocks) if (b.bothPeople) b.need!.point];
      expect(needs.where((n) => !n.ofFirst).length + both.length, 6);
      // Both have Mars in Virgo: one text for both.
      expect(both, contains(NeedPoint.mars));
      expect(guide.overview.keys, PairArea.values);
    });

    test('without a birth time: no descendant; Moon near a cusp left out', () {
      // 2000-01-03 noon UT: Moon about 7° into Sagittarius, uncertain without a time.
      final unknown = chartAt(2000, 1, 3, null, null);
      expect(moonSignUncertain(unknown), isTrue);
      final g = PairGuide.of(Synastry.compute(anna, unknown));
      final needs = [for (final c in g.chapters) for (final b in c.blocks) if (b.need != null) b.need!];
      expect(needs.where((n) => !n.ofFirst).map((n) => n.point), isNot(contains(NeedPoint.dsc)));
      expect(needs.where((n) => !n.ofFirst).map((n) => n.point), isNot(contains(NeedPoint.moon)));
      expect(needs.where((n) => n.ofFirst).map((n) => n.point), contains(NeedPoint.moon));
      final elements = [for (final c in g.chapters) for (final b in c.blocks) if (b.elements != null) b.elements!.body];
      expect(elements, isNot(contains(Body.moon)));
      expect(g.secondMoonUncertain, isTrue);
      // A noon Moon in the middle of a sign is certain enough.
      final mid = chartAt(2000, 1, 1, null, null);
      expect(mid.positions[Body.moon]!.degreeInSign, inInclusiveRange(moonUncertainDeg, 30 - moonUncertainDeg));
      expect(moonSignUncertain(mid), isFalse);
    });

    test('element pairs are unordered', () {
      expect(pairElementsKey(Body.sun, Element.water, Element.fire), 'pair_elements/sun/fire/water');
      expect(pairElementsKey(Body.sun, Element.fire, Element.water), 'pair_elements/sun/fire/water');
      expect(allKeysByFamily()['pair_elements'], hasLength(50));
      expect(allKeysByFamily()['pair_need'], hasLength(72));
      expect(allKeysByFamily()['pair_period'], hasLength(33));
    });
  });

  group('timeline', () {
    test('retrograde passes form one series with all exacts', () {
      TransitEvent stay(double s, double e, double x) => TransitEvent(
          transiting: Body.saturn, target: const ChartPoint.body(Body.venus), type: AspectType.square, side: 1,
          start: s, end: e, exacts: [x], passNumbers: const [1], passTotal: 3, station: null);
      final joined = transitSeriesOf([stay(0, 20, 10), stay(120, 150, 135), stay(250, 270, 260), stay(2000, 2020, 2010)]);
      expect(joined, hasLength(2));
      expect(joined.first.exacts, [10, 135, 260]);
      expect((joined.first.start, joined.first.end), (0, 270));
    });

    test('Saturn return of 2000-01-01 12:00 UT against DE440', () {
      final g = jsonDecode(File('test/golden/pair_saturn_return.json').readAsStringSync()) as Map<String, dynamic>;
      final natal = chartAt(2000, 1, 1, 12, 0);
      final want = (g['exacts'] as List).cast<num>().map((e) => e.toDouble()).toList();
      final tl = PairTimeline.compute(natal, natal, want.first - 400, want.last + 400);
      final ret = tl.periods.where((p) => p.ofFirst && p.cycle == 'saturn_return').toList();
      expect(ret, hasLength(1));
      expect(ret.single.kind, PairPeriodKind.cycle);
      expect(ret.single.series.exacts, hasLength(want.length));
      for (final (i, x) in ret.single.series.exacts.indexed) {
        expect(x, closeTo(want[i], 1));
      }
      // The same person twice: every straining period long enough is shared.
      expect(tl.periods.where((p) => p.isStraining && p.end - p.start >= pairSharedMinDays).every((p) => p.shared), isTrue);
      for (final p in tl.periods) {
        expect(allKeysByFamily()['pair_period'], contains(pairPeriodKey(p)));
      }
    });

    test('without a birth time: no Moon, no axis, no house ingress', () {
      final unknown = chartAt(2000, 1, 1, null, null);
      final from = julianDay(2026, 1, 1, 0), to = julianDay(2036, 1, 1, 0);
      final tl = PairTimeline.compute(unknown, unknown, from, to);
      expect(tl.periods, isNotEmpty);
      expect(tl.periods.map((p) => p.series.target), everyElement(isNot(anyOf(const ChartPoint.body(Body.moon), const ChartPoint.angle(Angle.asc)))));
      expect(tl.ingresses, isEmpty);
    });

    test('calm windows: gaps of 90 days without strain; support does not count', () {
      PairPeriod p(double s, double e, PairPeriodKind k) => PairPeriod(true, k, series(s, e), null, 0);
      final calm = PairTimeline.calmWindows([
        p(100, 200, PairPeriodKind.strain),
        p(250, 300, PairPeriodKind.strain),
        p(300, 600, PairPeriodKind.support),
        p(500, 520, PairPeriodKind.strain),
      ], 0, 700);
      expect([for (final c in calm) (c.start, c.end)], [(0, 100), (300, 500), (520, 700)]);
    });

    test('weight: slowness, big target, station, three passes', () {
      final s = TransitSeries(Body.pluto, const ChartPoint.body(Body.sun), AspectType.square, 1, 0, 900, [1, 2, 3], 5, const []);
      expect(pairPeriodWeight(s), TransitEngine.slowness(Body.pluto) + 15 + 10 + 5);
      final own = TransitSeries(Body.saturn, const ChartPoint.body(Body.saturn), AspectType.conjunction, 1, 0, 9, [1], null, const []);
      expect(pairPeriodWeight(own), TransitEngine.slowness(Body.saturn) + 5);
    });
  });
}
