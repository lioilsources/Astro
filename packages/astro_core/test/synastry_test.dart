import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:test/test.dart';

const sun = ChartPoint.body(Body.sun);
const moon = ChartPoint.body(Body.moon);
const venus = ChartPoint.body(Body.venus);
const mars = ChartPoint.body(Body.mars);
const saturn = ChartPoint.body(Body.saturn);
const asc = ChartPoint.angle(Angle.asc);
const mc = ChartPoint.angle(Angle.mc);

Chart chartAt(int year, int month, int day, int? hour, int? minute, {double lat = 50.0833, double lon = 14.4167}) =>
    Chart.compute(BirthData(
      moment: LocalMoment(year: year, month: month, day: day, hour: hour, minute: minute, basis: TimeBasis.ut),
      lat: lat,
      lon: lon,
    ));

void main() {
  const orbs = OrbConfig();

  group('inter-chart aspects', () {
    test('natal orbs: luminary bonus, point orb 3°', () {
      final a = synastryAspects({sun: 10, venus: 0, mars: 0}, {moon: 19.9, asc: 2.9, saturn: 95.9}, orbs);
      final sunMoon = a.singleWhere((x) => x.a == sun && x.b == moon);
      expect(sunMoon.type, AspectType.conjunction);
      expect(sunMoon.maxOrb, 10);
      expect(sunMoon.applying, isFalse);
      expect(a.any((x) => x.a == venus && x.b == asc && x.type == AspectType.conjunction), isTrue);
      expect(a.singleWhere((x) => x.a == mars && x.b == saturn).type, AspectType.square);
      // Just outside: 6.1° square and 3.1° to the ascendant.
      final b = synastryAspects({venus: 0, mars: 0}, {asc: 3.1, saturn: 96.1}, orbs);
      expect(b, isEmpty);
    });

    test('angle to angle is left out, the first side is always the first person', () {
      final a = synastryAspects({asc: 0, mc: 270, sun: 100}, {asc: 0, mc: 270, moon: 100}, orbs);
      expect(a.where((x) => x.a.isAngle && x.b.isAngle), isEmpty);
      expect(a.map((x) => x.a), everyElement(isIn([asc, mc, sun])));
      expect(a.map((x) => x.b), everyElement(isIn([asc, mc, moon])));
    });

    test('two real charts: overlays both ways, none into a chart without birth time', () {
      final x = chartAt(1980, 5, 14, 8, 30);
      final y = chartAt(1983, 11, 2, 19, 5);
      final s = Synastry.compute(x, y);
      expect(s.aspects, isNotEmpty);
      expect(s.overlays.where((o) => o.ofFirst), hasLength(10));
      expect(s.overlays.where((o) => !o.ofFirst), hasLength(10));
      for (final o in s.overlays.where((o) => o.ofFirst)) {
        expect(o.house, y.houses!.houseOf(x.positions[o.body]!.lon));
      }
      expect(s.twins, isNull);

      final noTime = Synastry.compute(x, chartAt(1983, 11, 2, null, null));
      expect(noTime.overlays.where((o) => o.ofFirst), isEmpty, reason: 'host without houses');
      expect(noTime.overlays.where((o) => !o.ofFirst), hasLength(10));
      expect(noTime.aspects.where((a) => a.b.isAngle), isEmpty);
    });
  });

  group('twins (plan 10.4)', () {
    test('25 minutes apart: near-identical, axes and houses differ', () {
      final a = chartAt(1990, 3, 10, 6, 0);
      final b = chartAt(1990, 3, 10, 6, 25);
      final s = Synastry.compute(a, b);
      final t = s.twins!;
      expect(t.minutesApart, closeTo(25, 0.01));
      expect(t.maxPlanetDiff, lessThan(1));
      // The ascendant moves roughly a degree every four minutes.
      expect(t.ascDiff!.abs(), greaterThan(3));
      expect(t.mcDiff!.abs(), greaterThan(5));
      expect(t.cuspDiffs, hasLength(12));
      for (final MapEntry(key: body, value: (ha, hb)) in t.houseChanges.entries) {
        expect(a.houseOf(body), ha);
        expect(b.houseOf(body), hb);
      }
      // The ten same-planet conjunctions are replaced by the twins note.
      final f = synastryFactorsOf(s);
      expect(f.where((x) => x.aspect != null && x.aspect!.a == x.aspect!.b && x.aspect!.type == AspectType.conjunction), isEmpty);
    });

    test('a few hours apart the Moon breaks the 1° rule', () {
      expect(twinsDiff(chartAt(1990, 3, 10, 6, 0), chartAt(1990, 3, 10, 9, 0)), isNull);
    });

    test('twins without birth time: no axes', () {
      final t = twinsDiff(chartAt(1990, 3, 10, null, null), chartAt(1990, 3, 10, null, null))!;
      expect(t.ascDiff, isNull);
      expect(t.houseChanges, isEmpty);
    });
  });

  group('keys', () {
    test('families have the sizes from plan 10.4', () {
      final k = allKeysByFamily();
      expect(k['synastry'], hasLength(165));
      expect(k['synastry_point'], hasLength(60));
      expect(k['synastry_house'], hasLength(120));
      expect(k['glossary'], contains('glossary/twins'));
    });

    test('planet pairs are unordered, angles map to the point family', () {
      expect(synastryKey(const Aspect(moon, sun, AspectType.trine, 1, 8, false)), 'synastry/sun/moon/harmonious');
      expect(synastryKey(const Aspect(sun, moon, AspectType.sextile, 1, 6, false)), 'synastry/sun/moon/harmonious');
      expect(synastryKey(const Aspect(mars, mars, AspectType.opposition, 1, 8, false)), 'synastry/mars/mars/tense');
      expect(synastryKey(const Aspect(asc, venus, AspectType.conjunction, 1, 3, false)), 'synastry_point/asc/venus/conjunction');
      expect(synastryKey(const Aspect(saturn, mc, AspectType.square, 1, 3, false)), 'synastry_point/mc/saturn/tense');
    });

    test('every factor of a real pair has a known key', () {
      final known = {for (final f in allKeysByFamily().values) ...f};
      final f = synastryFactorsOf(Synastry.compute(chartAt(1980, 5, 14, 8, 30), chartAt(1983, 11, 2, 19, 5)));
      expect(f, isNotEmpty);
      for (final x in f) {
        expect(known, contains(x.key));
      }
      expect(f.where((x) => x.kind == FactorKind.synastryHouse), hasLength(20));
    });
  });

  test('only the partner relationship shows the partner layer', () {
    expect([for (final r in Relationship.values) if (r.showsPartnerLayer) r], [Relationship.partner]);
    expect(Relationship.parentChild.showsPartnerLayer, isFalse);
  });

  test('partner field round-trips through JSON', () {
    const e = ContentEntry(key: 'synastry/sun/moon/conjunction', title: 'x', text: 't', partner: 'p');
    expect(ContentEntry.fromJson(e.toJson()).partner, 'p');
    expect(const ContentEntry(key: 'k', title: 'x', text: 't').toJson().containsKey('partner'), isFalse);
  });
}
