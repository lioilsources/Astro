import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

List<ChartPattern> of(PatternKind k, Map<Body, double> lons, {double? asc, double? mc}) =>
    findPatterns(lons, asc: asc, mc: mc).where((p) => p.kind == k).toList();

void main() {
  group('grand trine', () {
    test('three trines in fire', () {
      final p = of(PatternKind.grandTrine, {Body.venus: 10, Body.mars: 130, Body.jupiter: 250});
      expect(p, hasLength(1));
      expect(p.single.element, Element.fire);
      expect(p.single.bodies, [Body.venus, Body.mars, Body.jupiter]);
      expect(p.single.sides, hasLength(3));
    });

    test('orb edge: 6° holds, 6.1° breaks', () {
      expect(of(PatternKind.grandTrine, {Body.venus: 10, Body.mars: 130, Body.jupiter: 255.9}), hasLength(1));
      expect(of(PatternKind.grandTrine, {Body.venus: 10, Body.mars: 130, Body.jupiter: 256.1}), isEmpty);
    });

    test('out-of-sign corner takes the element of the majority', () {
      final p = of(PatternKind.grandTrine, {Body.venus: 29, Body.mars: 152, Body.jupiter: 268});
      expect(p.single.element, Element.fire);
    });

    test('a conjunction at a corner merges into one pattern', () {
      final p = of(PatternKind.grandTrine, {Body.mercury: 12, Body.venus: 10, Body.mars: 130, Body.jupiter: 250});
      expect(p, hasLength(1));
      expect(p.single.bodies, [Body.mercury, Body.venus, Body.mars, Body.jupiter]);
    });
  });

  group('T-square', () {
    test('apex and cardinal modality', () {
      final p = of(PatternKind.tSquare, {Body.mars: 10, Body.saturn: 190, Body.venus: 100});
      expect(p, hasLength(1));
      expect(p.single.apexes, [Body.venus]);
      expect(p.single.modality, Modality.cardinal);
    });

    test('no T-square when the square is out of orb', () {
      expect(of(PatternKind.tSquare, {Body.mars: 10, Body.saturn: 190, Body.venus: 107}), isEmpty);
    });

    test('conjunct apexes are both listed', () {
      final p = of(PatternKind.tSquare, {Body.mars: 10, Body.saturn: 190, Body.venus: 100, Body.mercury: 103});
      expect(p.single.apexes, [Body.mercury, Body.venus]);
    });
  });

  test('grand cross swallows its T-squares', () {
    final lons = {Body.mars: 10.0, Body.jupiter: 100.0, Body.saturn: 190.0, Body.uranus: 280.0};
    final p = of(PatternKind.grandCross, lons);
    expect(p, hasLength(1));
    expect(p.single.modality, Modality.cardinal);
    expect(p.single.sides, hasLength(6));
    expect(of(PatternKind.tSquare, lons), isEmpty);
  });

  group('yod', () {
    test('sextile with a quincunx apex', () {
      final p = of(PatternKind.yod, {Body.mars: 10, Body.jupiter: 70, Body.saturn: 220});
      expect(p.single.apexes, [Body.saturn]);
      expect(p.single.sides.where((a) => a.type == AspectType.quincunx), hasLength(2));
    });

    test('quincunx orb is 2°', () {
      expect(of(PatternKind.yod, {Body.mars: 10, Body.jupiter: 70, Body.saturn: 221.9}), hasLength(1));
      expect(of(PatternKind.yod, {Body.mars: 10, Body.jupiter: 70, Body.saturn: 222.1}), isEmpty);
    });

    test('quincunx never shows in the aspect table', () {
      for (var y = 1950; y < 2050; y += 3) {
        final c = Chart.compute(BirthData(
          moment: LocalMoment(year: y, month: 3, day: 7, hour: 9, minute: 0, basis: TimeBasis.ut),
          lat: 50,
          lon: 14.4,
        ));
        expect(c.aspects.where((a) => a.type == AspectType.quincunx), isEmpty);
      }
    });
  });

  test('kite: grand trine plus an opposition with two sextiles', () {
    final lons = {Body.venus: 10.0, Body.mars: 130.0, Body.jupiter: 250.0, Body.saturn: 190.0};
    final k = of(PatternKind.kite, lons);
    expect(k, hasLength(1));
    expect(k.single.element, Element.fire);
    expect(of(PatternKind.grandTrine, lons), hasLength(1));
    expect(of(PatternKind.kite, {...lons, Body.saturn: 198.0}), isEmpty);
  });

  test('cradle: opposition with three sextiles and two trines', () {
    final lons = {Body.mars: 0.0, Body.venus: 60.0, Body.jupiter: 120.0, Body.saturn: 180.0};
    expect(of(PatternKind.cradle, lons), hasLength(1));
    expect(of(PatternKind.mysticRectangle, lons), isEmpty);
    // A broken middle sextile breaks the cradle.
    expect(of(PatternKind.cradle, {...lons, Body.jupiter: 127.0}), isEmpty);
  });

  test('mystic rectangle: two oppositions, two sextiles, two trines', () {
    final lons = {Body.mars: 0.0, Body.venus: 60.0, Body.saturn: 180.0, Body.jupiter: 240.0};
    expect(of(PatternKind.mysticRectangle, lons), hasLength(1));
    expect(of(PatternKind.grandCross, lons), isEmpty);
    expect(of(PatternKind.mysticRectangle, {...lons, Body.jupiter: 247.0}), isEmpty);
  });

  test('modality excess and lack', () {
    final lons = {
      Body.sun: 0.0, Body.moon: 95.0, Body.mercury: 185.0, Body.venus: 275.0, Body.mars: 5.0, Body.jupiter: 100.0,
      Body.saturn: 65.0, Body.uranus: 70.0, Body.neptune: 155.0, Body.pluto: 160.0,
    };
    final ps = findPatterns(lons);
    final excess = ps.where((p) => p.kind == PatternKind.modalityExcess).toList();
    final lack = ps.where((p) => p.kind == PatternKind.modalityLack).toList();
    expect(excess.single.modality, Modality.cardinal);
    expect(excess.single.bodies, hasLength(6));
    expect(lack.single.modality, Modality.fixed);
    // Five cardinal planets are not an excess; two fixed are not a lack.
    final balanced = findPatterns({...lons, Body.sun: 40.0, Body.moon: 45.0});
    expect(balanced.where((p) => p.kind == PatternKind.modalityExcess || p.kind == PatternKind.modalityLack), isEmpty);
  });

  group('hemispheres', () {
    // ASC 0°, MC 270°: above the horizon is 180°–360°, east is 270°–90°.
    final lons = {
      Body.sun: 190.0, Body.moon: 200.0, Body.mercury: 210.0, Body.venus: 230.0, Body.mars: 250.0,
      Body.jupiter: 280.0, Body.saturn: 300.0, Body.uranus: 320.0, Body.neptune: 340.0, Body.pluto: 10.0,
    };
    test('nine planets above the horizon', () {
      final p = of(PatternKind.hemisphere, lons, asc: 0, mc: 270);
      expect(p.map((x) => x.hemisphere), [Hemisphere.above]);
      expect(p.single.bodies, hasLength(9));
    });
    test('eight are not enough', () {
      expect(of(PatternKind.hemisphere, {...lons, Body.sun: 100.0}, asc: 0, mc: 270), isEmpty);
    });
    test('east of the meridian', () {
      final p = of(PatternKind.hemisphere, {for (final b in Body.planets) b: 280.0 + b.index * 15}, asc: 0, mc: 270);
      expect(p.map((x) => x.hemisphere), contains(Hemisphere.east));
    });
    test('no hemispheres without a birth time', () {
      expect(of(PatternKind.hemisphere, lons), isEmpty);
    });
  });

  test('unaspected planet; a quincunx does not count as an aspect', () {
    expect(of(PatternKind.unaspected, {Body.mars: 0, Body.jupiter: 120, Body.saturn: 45}).map((p) => p.bodies.single), [Body.saturn]);
    expect(of(PatternKind.unaspected, {Body.mars: 0, Body.jupiter: 120, Body.saturn: 150}).map((p) => p.bodies.single), [Body.saturn]);
    expect(of(PatternKind.unaspected, {Body.mars: 0, Body.jupiter: 120, Body.saturn: 240}), isEmpty);
  });

  test('real charts: patterns are consistent with the aspect table', () {
    for (var y = 1900; y <= 2100; y += 5) {
      final c = Chart.compute(BirthData(
        moment: LocalMoment(year: y, month: (y % 12) + 1, day: 14, hour: (y * 5) % 24, minute: 0, basis: TimeBasis.ut),
        lat: 50,
        lon: 14.4,
      ));
      final table = {
        for (final a in c.aspects)
          if (a.a.body != null && a.b.body != null) {a.a.body, a.b.body}: a.type
      };
      for (final p in c.patterns.where((p) => p.kind.isShape)) {
        for (final s in p.sides.where((s) => s.type != AspectType.quincunx)) {
          expect(table.entries.any((e) => e.key.containsAll({s.a.body, s.b.body}) && e.value == s.type), isTrue, reason: '$p $s');
        }
      }
    }
  });
}
