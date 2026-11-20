import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:test/test.dart';

void main() {
  final known = {for (final f in allKeysByFamily().values) ...f};

  test('every key the engine produces belongs to a content family', () {
    for (var y = 1900; y <= 2100; y += 7) {
      for (final lat in [-35.0, 0.0, 50.1, 64.0]) {
        final c = Chart.compute(BirthData(
          moment: LocalMoment(year: y, month: (y % 12) + 1, day: 11, hour: (y * 7) % 24, minute: 13, basis: TimeBasis.ut),
          lat: lat,
          lon: 14.4,
        ));
        for (final f in factorsOf(c)) {
          expect(known, contains(f.key));
        }
        final e = TransitEngine(c);
        final from = julianDay(y, 6, 1, 0);
        for (final t in e.events(from, from + 3, bodies: [Body.moon, Body.sun])) {
          expect(known, contains(transitKey(t)));
        }
        for (final i in e.ingresses(from, from + 3, bodies: [Body.moon])) {
          expect(known, contains(transitInHouseKey(i.body, i.house)));
        }
      }
    }
  });

  test('pattern family has the 56 keys of plan 10.1', () {
    expect(allKeysByFamily()['pattern'], hasLength(56));
  });

  test('pattern keys: T-square gives shape and apex, yod only the apex', () {
    final t = findPatterns({Body.mars: 10, Body.saturn: 190, Body.venus: 100}).firstWhere((p) => p.kind == PatternKind.tSquare);
    expect(patternKeysOf(t), ['pattern/t_square/cardinal', 'pattern/t_square_apex/venus']);
    final y = findPatterns({Body.mars: 10, Body.jupiter: 70, Body.saturn: 220}).firstWhere((p) => p.kind == PatternKind.yod);
    expect(patternKeysOf(y), ['pattern/yod_apex/saturn']);
    for (final p in [t, y]) {
      expect(known, containsAll(patternKeysOf(p)));
    }
  });

  test('aspect keys order planets canonically', () {
    final a = Aspect(const ChartPoint.body(Body.saturn), const ChartPoint.body(Body.sun), AspectType.trine, 1, 6, true);
    expect(aspectKey(a), 'aspect/sun/saturn/trine');
    final p = Aspect(const ChartPoint.angle(Angle.mc), const ChartPoint.body(Body.mars), AspectType.square, 1, 3, true);
    expect(aspectKey(p), 'aspect_point/mc/mars/tense');
    final n = Aspect(const ChartPoint.body(Body.meanNode), const ChartPoint.angle(Angle.asc), AspectType.square, 1, 3, true);
    expect(aspectKey(n), isNull);
  });
}
