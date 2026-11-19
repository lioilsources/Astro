import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

const praha = BirthData(
  moment: LocalMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, basis: TimeBasis.ut),
  lat: 50.0833,
  lon: 14.4167,
);

void main() {
  test('reference chart matches the old Astromat within tolerance', () {
    final c = Chart.compute(praha);
    const astromat = {
      Body.sun: 280.377, Body.moon: 223.317, Body.mercury: 271.904, Body.venus: 241.575,
      Body.mars: 327.978, Body.jupiter: 25.263, Body.saturn: 40.393, Body.uranus: 314.818,
      Body.neptune: 303.219, Body.meanNode: 125.043,
    };
    astromat.forEach((b, v) => expect(angDist(c.positions[b]!.lon, v) * 60, lessThan(2.0), reason: b.name));
    expect(angDist(c.asc!, 49.69) * 60, lessThan(1.0));
    expect(angDist(c.mc!, 293.047) * 60, lessThan(1.0));
    expect(c.houses!.system, HouseSystem.placidus);
  });

  test('default house system by latitude', () {
    expect(defaultHouseSystem(50).system, HouseSystem.placidus);
    expect(defaultHouseSystem(63).warnUnequal, isTrue);
    expect(defaultHouseSystem(-70).system, HouseSystem.porphyry);
    expect(housesFromRamc(HouseSystem.placidus, 100, 70, 23.44).defined, isFalse);
    expect(housesFromRamc(HouseSystem.koch, 100, -70, 23.44).defined, isFalse);
  });

  test('porphyry trisects the quadrants', () {
    final h = housesFromRamc(HouseSystem.porphyry, 123.4, 48, 23.44);
    final s = h.sizes;
    expect(s[9], closeTo(s[10], 1e-9));
    expect(s[10], closeTo(s[11], 1e-9));
    expect(s[0], closeTo(s[1], 1e-9));
    expect(s.reduce((a, b) => a + b), closeTo(360, 1e-9));
  });

  test('unknown time → no houses, no angles in aspects', () {
    final c = Chart.compute(const BirthData(
        moment: LocalMoment(year: 1990, month: 5, day: 5, zone: 'Europe/Prague'), lat: 50, lon: 14));
    expect(c.houses, isNull);
    expect(c.houseOf(Body.sun), isNull);
    expect(c.aspects.any((a) => a.a.isAngle || a.b.isAngle), isFalse);
  });

  test('historical chart in the 18th century has Pluto from the DE440 table', () {
    final c = Chart.compute(const BirthData(
      moment: LocalMoment(year: 1769, month: 8, day: 15, hour: 11, minute: 30, basis: TimeBasis.lmt),
      lat: 41.92,
      lon: 8.74,
    ));
    expect(c.missing, isEmpty);
    expect(c.positions[Body.sun]!.sign, Sign.leo);
  });

  test('aspect matching: orb, applying, separating', () {
    final cfg = const OrbConfig();
    double orb(AspectType t) => cfg.base[t]!;
    final applying = matchAspect(95, 1, 0, 0, orb)!; // 95° and moving away from the square → separating
    expect(applying.type, AspectType.square);
    expect(applying.orb, closeTo(5, 1e-9));
    expect(applying.applying, isFalse);
    expect(matchAspect(85, 1, 0, 0, orb)!.applying, isTrue);
    expect(matchAspect(45, 1, 0, 0, orb), isNull);
    expect(matchAspect(358, 0, 3, 0, orb)!.type, AspectType.conjunction);
  });

  test('dignities', () {
    expect(dignityOf(Body.mars, Sign.scorpio), Dignity.domicile);
    expect(dignityOf(Body.mars, Sign.cancer), Dignity.fall);
    expect(dignityOf(Body.venus, Sign.aries), Dignity.detriment);
    expect(dignityOf(Body.sun, Sign.aries), Dignity.exaltation);
    expect(traditionalRuler(Sign.aquarius), Body.saturn);
    expect(modernRuler(Sign.aquarius), Body.uranus);
  });
}
