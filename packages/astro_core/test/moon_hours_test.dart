import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:test/test.dart';

const prague = (lat: 50.0833, lon: 14.4167);
const tromso = (lat: 69.65, lon: 18.96);

double jd(int y, int m, int d, [double h = 0]) => julianDay(y, m, d, h);

void main() {
  group('planetary hours', () {
    test('weekday rulers follow from the Chaldean order', () {
      // 24 hours later the order has moved by 3: Sun → Moon → Mars → Mercury …
      for (var wd = 1; wd <= 7; wd++) {
        final r = dayRulerOfWeekday(wd);
        final next = dayRulerOfWeekday(wd % 7 + 1);
        expect(chaldeanOrder[(chaldeanOrder.indexOf(r) + 24) % 7], next);
      }
      expect(dayRulerOfWeekday(DateTime.sunday), Body.sun);
      expect(dayRulerOfWeekday(DateTime.saturday), Body.saturn);
    });

    test('a week in Prague: 24 contiguous hours, equal within day and night', () {
      for (var d = 16; d <= 22; d++) {
        final day = PlanetaryHours.day(2026, 11, d, prague.lat, prague.lon)!;
        expect(day.ruler, dayRulerOfWeekday(DateTime.utc(2026, 11, d).weekday));
        expect(day.hours, hasLength(24));
        expect(day.hours.first.ruler, day.ruler);
        expect(day.hours.first.start, day.sunrise);
        expect(day.hours[12].start, day.sunset);
        expect(day.hours.last.end, day.nextSunrise);
        for (var i = 1; i < 24; i++) {
          expect(day.hours[i].start, closeTo(day.hours[i - 1].end, 1e-9));
          expect(day.hours[i].ruler, chaldeanOrder[(chaldeanOrder.indexOf(day.hours[i - 1].ruler) + 1) % 7]);
        }
        // November: short days, long nights.
        expect(day.dayHourLength, lessThan(day.nightHourLength));
        final next = PlanetaryHours.day(2026, 11, d + 1, prague.lat, prague.lon)!;
        expect(next.sunrise, closeTo(day.nextSunrise, 1e-6));
      }
    });

    test('before sunrise the hour belongs to the previous planetary day', () {
      final fri = PlanetaryHours.day(2026, 11, 20, prague.lat, prague.lon)!;
      final early = PlanetaryHours.dayAt(fri.sunrise - 0.01, prague.lat, prague.lon)!;
      expect(early.day, 19);
      expect(PlanetaryHours.hourAt(fri.sunrise - 0.01, prague.lat, prague.lon)!.number, 24);
      expect(PlanetaryHours.hourAt(fri.sunrise + 0.001, prague.lat, prague.lon)!.ruler, Body.venus);
    });

    test('Tokyo: sunrise belongs to the local date although it is the previous UT day', () {
      final d = PlanetaryHours.day(2026, 6, 21, 35.68, 139.69)!;
      expect(d.ruler, Body.sun);
      final local = dateTimeUtcFromJd(d.sunrise).add(const Duration(hours: 9));
      expect(local.day, 21);
      expect(local.hour, 4);
    });

    test('no hours where the Sun does not rise or set', () {
      expect(PlanetaryHours.day(2026, 6, 21, tromso.lat, tromso.lon), isNull);
      expect(PlanetaryHours.day(2026, 12, 21, tromso.lat, tromso.lon), isNull);
      expect(PlanetaryHours.hourAt(jd(2026, 6, 21, 12), tromso.lat, tromso.lon), isNull);
      expect(SunRiseSet.of(2026, 12, 21, tromso.lat, tromso.lon).rise, isNull);
      expect(PlanetaryHours.day(2026, 3, 21, tromso.lat, tromso.lon), isNotNull);
    });
  });

  group('moon', () {
    test('phases are 45° sectors from the principal points', () {
      expect(MoonPhase.ofElongation(0), MoonPhase.newMoon);
      expect(MoonPhase.ofElongation(44.9), MoonPhase.newMoon);
      expect(MoonPhase.ofElongation(45), MoonPhase.crescent);
      expect(MoonPhase.ofElongation(180), MoonPhase.fullMoon);
      expect(MoonPhase.ofElongation(359.9), MoonPhase.balsamic);
      expect(MoonPhase.ofElongation(-10), MoonPhase.balsamic);
      expect([for (final p in MoonPhase.values) p.id], moonPhaseIds);
    });

    test('lunations alternate and eclipses are flagged', () {
      final l = Lunar.lunations(jd(2023, 1, 1), jd(2027, 1, 1));
      for (var i = 1; i < l.length; i++) {
        expect(l[i].kind.index, (l[i - 1].kind.index + 1) % 4);
      }
      Eclipse? at(int y, int m, int d) =>
          l.firstWhere((x) => x.isNewOrFull && (x.jd - jd(y, m, d, 12)).abs() < 1).eclipse;
      expect(at(2024, 4, 8)!.degree, EclipseDegree.total);
      expect(at(2024, 4, 8)!.kind, EclipseKind.solar);
      expect(at(2023, 10, 14)!.degree, EclipseDegree.annular);
      expect(at(2026, 2, 17)!.degree, EclipseDegree.annular);
      expect(at(2026, 8, 12)!.degree, EclipseDegree.total);
      expect(at(2025, 3, 14)!.kind, EclipseKind.lunar);
      expect(at(2025, 3, 14)!.degree, EclipseDegree.total);
      expect(at(2024, 5, 8), isNull);
      // Eclipses come in seasons: 4–7 a year.
      for (var y = 2023; y < 2027; y++) {
        final n = l.where((x) => x.eclipse != null && x.jd >= jd(y, 1, 1) && x.jd < jd(y + 1, 1, 1)).length;
        expect(n, inInclusiveRange(4, 7), reason: '$y');
      }
      expect(l.where((x) => !x.isNewOrFull).every((x) => x.eclipse == null), isTrue);
    });

    test('sign ingresses every 2–3 days', () {
      final ing = Lunar.ingresses(jd(2026, 11, 1), jd(2026, 12, 1));
      expect(ing.length, inInclusiveRange(12, 14));
      for (var i = 1; i < ing.length; i++) {
        expect(ing[i].sign.index, (ing[i - 1].sign.index + 1) % 12);
        expect(ing[i].jd - ing[i - 1].jd, inInclusiveRange(1.9, 2.9));
      }
      for (final i in ing) {
        expect(Sign.ofLongitude(Ephemeris.longitude(Body.moon, i.jd + 1e-4)), i.sign);
        expect(Sign.ofLongitude(Ephemeris.longitude(Body.moon, i.jd - 1e-4)).index, (i.sign.index + 11) % 12);
      }
    });

    test('void of course: from the last aspect to the next ingress', () {
      final from = jd(2026, 11, 1), to = jd(2026, 12, 1);
      final modern = Lunar.voidOfCourse(from, to);
      final trad = Lunar.voidOfCourse(from, to, traditionalOnly: true);
      final ing = Lunar.ingresses(from - 3, to + 3);
      expect(modern.length, inInclusiveRange(12, 14));
      for (final v in modern) {
        expect(v.start, lessThanOrEqualTo(v.end));
        expect(ing.any((i) => (i.jd - v.end).abs() < 1e-4 && i.sign == v.nextSign), isTrue);
        final a = v.lastAspect;
        if (a != null) {
          // The aspect is exact at the start of the period.
          final dev = angDiff(Ephemeris.longitude(Body.moon, a.jd), Ephemeris.longitude(a.body, a.jd)).abs();
          expect([for (final t in AspectType.major) (dev - t.angle).abs()].reduce((x, y) => x < y ? x : y), lessThan(0.01));
          expect(a.body, isNot(Body.moon));
        }
        expect(Lunar.voidAt((v.start + v.end) / 2)?.end, closeTo(v.end, 1e-4));
      }
      // Fewer planets → the last aspect comes earlier or at the same time.
      for (final t in trad) {
        final m = modern.firstWhere((m) => (m.end - t.end).abs() < 1e-4);
        expect(t.start, lessThanOrEqualTo(m.start + 1e-9));
        expect(const [Body.uranus, Body.neptune, Body.pluto], isNot(contains(t.lastAspect?.body)));
      }
    });

    test('natal moon phase and lunation house', () {
      final c = Chart.compute(const BirthData(
        moment: LocalMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, basis: TimeBasis.ut),
        lat: 50.0833,
        lon: 14.4167,
      ));
      // Moon ~223°, Sun ~280°: elongation ~303° → last quarter phase.
      expect(natalMoonPhase(c), MoonPhase.lastQuarter);
      expect(factorsOf(c).map((f) => f.key), contains('natal_moon_phase/last_quarter'));
      final l = Lunar.lunations(jd(2026, 11, 1), jd(2026, 12, 1), kinds: {LunationKind.newMoon, LunationKind.fullMoon});
      expect(l, hasLength(2));
      for (final x in l) {
        expect(lunationHouse(c, x), c.houses!.houseOf(x.lon));
        expect(lunationInHouseKey(x.kind, lunationHouse(c, x)!), startsWith('lunation_in_house/'));
      }
    });
  });

  test('content keys of R2 belong to their families', () {
    final k = allKeysByFamily();
    final known = {for (final f in k.values) ...f};
    const r2 = ['planetary_hour', 'planetary_day', 'moon_phase', 'natal_moon_phase', 'moon_today', 'lunation_in_house', 'void_of_course', 'eclipse'];
    expect([for (final f in r2) k[f]!.length].reduce((a, b) => a + b), 69);
    for (final b in chaldeanOrder) {
      expect(known, containsAll([planetaryHourKey(b), planetaryDayKey(b)]));
    }
    for (final p in MoonPhase.values) {
      expect(known, containsAll([moonPhaseKey(p), natalMoonPhaseKey(p)]));
    }
    for (final s in Sign.values) {
      expect(known, contains(moonTodayKey(s)));
    }
    for (final e in EclipseKind.values) {
      expect(known, contains(eclipseKey(e)));
    }
    expect(known, contains(voidOfCourseKey));
    expect(lunationInHouseKey(LunationKind.firstQuarter, 3), isNull);
  });

  test('residence location round-trips and defaults to the birth place', () {
    const b = BirthData(moment: LocalMoment(year: 1990, month: 5, day: 1, zone: 'Europe/Prague'), lat: 49.2, lon: 16.6, placeName: 'Brno');
    final g = GeoLocation.ofBirth(b);
    expect(g, const GeoLocation(lat: 49.2, lon: 16.6, name: 'Brno', zone: 'Europe/Prague'));
    expect(GeoLocation.fromJson(g.toJson()), g);
  });
}
