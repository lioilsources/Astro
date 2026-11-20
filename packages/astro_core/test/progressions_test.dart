import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:test/test.dart';

/// Tolerances, see docs/ephemeris.md.
const moonArcsec = 15.0;
const returnSeconds = 15.0;

final _golden = jsonDecode(File('test/golden/progressions.json').readAsStringSync()) as Map<String, dynamic>;
List<Map<String, dynamic>> _rows(String k) => (_golden[k] as List).cast<Map<String, dynamic>>();

/// Natal chart for an exact UT instant at Prague.
Chart natalAt(double jdUt, {double lat = 50.0833, double lon = 14.4167}) {
  final u = dateTimeUtcFromJd(jdUt);
  return Chart.computeAt(
    BirthData(
      moment: LocalMoment(year: u.year, month: u.month, day: u.day, hour: u.hour, minute: u.minute, basis: TimeBasis.ut),
      lat: lat,
      lon: lon,
    ),
    ResolvedTime(jdUt: jdUt, offsetHours: 0, basisUsed: TimeBasis.ut),
  );
}

void main() {
  test('progressed Moon and Sun vs skyfield + DE440 (J2000 + 30 years and more)', () {
    var worst = 0.0;
    for (final r in _rows('progressed')) {
      final natal = natalAt((r['natalJdUt'] as num).toDouble());
      final age = (r['age'] as num).toDouble();
      final p = Progression.at(natal, natal.time.jdUt + age * tropicalYearDays);
      expect(p.jdUt, closeTo((r['jdUt'] as num).toDouble(), 1e-6));
      for (final (b, k) in [(Body.moon, 'moon'), (Body.sun, 'sun')]) {
        final d = angDist(p.positions[b]!.lon, (r[k] as num).toDouble()) * 3600;
        if (d > worst) worst = d;
        expect(d, lessThan(moonArcsec), reason: '${r['natal']} age $age $k: $d″');
      }
    }
    final j30 = _rows('progressed').firstWhere((r) => r['natal'] == 'j2000' && r['age'] == 30);
    final p30 = Progression.at(natalAt(2451545.0), 2451545.0 + 30 * tropicalYearDays);
    expect(p30.moon.sign, Sign.ofLongitude((j30['moon'] as num).toDouble()));
    print('progressions: worst ${worst.toStringAsFixed(1)}″');
  });

  test('solar return moment vs skyfield + DE440 to seconds', () {
    var worst = 0.0;
    for (final r in _rows('solarReturns')) {
      final natalJd = (r['natalJdUt'] as num).toDouble();
      final ref = (r['jdUt'] as num).toDouble();
      // Same target longitude as the reference: measures the Sun ephemeris and ΔT only.
      final got = SolarReturn.find((r['sunLon'] as num).toDouble(), natalJd + (r['years'] as int) * tropicalYearDays);
      final d = (got - ref).abs() * 86400;
      if (d > worst) worst = d;
      expect(d, lessThan(returnSeconds), reason: '${r['natal']} +${r['years']}: $d s');
      // End to end from the engine's own natal Sun.
      final natal = natalAt(natalJd);
      final sr = SolarReturn.ofAge(natal, r['years'] as int);
      expect(sr.year, 2000 + (r['natal'] == 'j2000' ? 0 : (r['natal'] == '1975' ? -25 : -48)) + (r['years'] as int));
      expect((sr.jdUt - ref).abs() * 86400, lessThan(returnSeconds + 60),
          reason: "end to end ${r['natal']} +${r['years']}");
      expect(angDist(Ephemeris.longitude(Body.sun, sr.jdUt), natal.positions[Body.sun]!.lon) * 3600, lessThan(0.1));
    }
    print('solar returns: worst ${worst.toStringAsFixed(1)} s');
  });

  test('same-year solar return for two places: same planets, different houses', () {
    final natal = natalAt(2451545.0);
    final sr = SolarReturn.ofYear(natal, 2030);
    final prague = sr.chartAt(const GeoLocation(lat: 50.0833, lon: 14.4167, name: 'Praha'));
    final ny = sr.chartAt(const GeoLocation(lat: 40.71, lon: -74.01, name: 'New York'));
    for (final b in Body.planets) {
      expect(prague.positions[b]!.lon, closeTo(ny.positions[b]!.lon, 1e-9));
    }
    expect(angDist(prague.asc!, ny.asc!), greaterThan(30));
    expect(prague.houses!.cusps, isNot(equals(ny.houses!.cusps)));
    expect(prague.time.jdUt, sr.jdUt);
  });

  test('progressed angles: MC by solar arc, ASC from that MC', () {
    final natal = natalAt(2451545.0);
    final p = Progression.at(natal, natal.time.jdUt + 30 * tropicalYearDays);
    expect(p.solarArc, closeTo(30.6, 0.6)); // ~1°/year in January
    expect(angDiff(p.mc!, natal.mc!), closeTo(p.solarArc, 1e-9));
    final eps = Ephemeris.trueObliquity(p.jdUt);
    final ramc = p.houses!.ramc;
    expect(housesFromRamc(natal.houses!.system, ramc, natal.birth.lat, eps).asc, closeTo(p.asc!, 1e-9));
  });

  test('progressed aspects respect the 1° orb and own-place rule', () {
    final natal = natalAt(2451545.0);
    for (var age = 0; age <= 90; age += 3) {
      final p = Progression.at(natal, natal.time.jdUt + age * tropicalYearDays);
      for (final a in p.aspects) {
        expect(a.orb, lessThanOrEqualTo(progressedOrb));
        expect(progressedMovers, contains(a.progressed));
        if (a.natal.body == a.progressed) expect(a.progressed, Body.moon);
      }
    }
    // At birth every mover sits on itself: only the Moon's own conjunction counts.
    final p0 = Progression.at(natal, natal.time.jdUt);
    expect(p0.aspects.where((a) => a.natal.body == a.progressed).map((a) => a.progressed), [Body.moon]);
  });

  test('life milestones: progressed Moon changes sign about every 2.5 years', () {
    final natal = natalAt(2451545.0);
    final m = progressedMilestones(natal, years: 60);
    final signs = m.where((x) => x.kind == MilestoneKind.moonSign).toList();
    expect(signs.length, inInclusiveRange(20, 26));
    for (final s in signs) {
      final p = Progression.at(natal, s.jdUt + 1);
      expect(p.moon.sign, s.sign);
      expect(p.moon.degreeInSign, lessThan(0.1));
    }
    expect(m.where((x) => x.kind == MilestoneKind.sunSign).length, inInclusiveRange(1, 3));
    final phases = m.where((x) => x.kind == MilestoneKind.lunarPhase).toList();
    expect(phases.length, inInclusiveRange(14, 18)); // 8 phases per 29.5 years
    expect(m.where((x) => x.kind == MilestoneKind.moonHouse), isNotEmpty);
    for (var i = 1; i < m.length; i++) {
      expect(m[i].jdUt, greaterThanOrEqualTo(m[i - 1].jdUt));
    }
  });

  test('progression and solar return keys exist and factors map to them', () {
    final known = {for (final f in allKeysByFamily().values) ...f};
    expect(allKeysByFamily()['progressed'], hasLength(12 + 12 + 12 + 8 + 2));
    expect(allKeysByFamily()['solar_return'], hasLength(12 + 12 + 40));
    final natal = natalAt(2451545.0);
    for (var age = 0; age <= 90; age += 5) {
      final p = Progression.at(natal, natal.time.jdUt + age * tropicalYearDays);
      for (final f in progressionFactorsOf(p)) {
        expect(known, contains(f.key));
      }
      for (final a in p.aspects) {
        expect(known, contains(progressedAspectKey(a)));
        expect(known, contains(progressedModifierKey(a)));
      }
    }
    final sr = SolarReturn.ofYear(natal, 2031).chartAt(const GeoLocation(lat: 50.0833, lon: 14.4167));
    final keys = solarReturnFactorsOf(sr).map((f) => f.key).toList();
    expect(keys.first, startsWith('solar_return/asc/'));
    expect(keys, contains(startsWith('solar_return/sun_in_house/')));
    for (final k in keys) {
      expect(known, contains(k));
    }
    expect(isShadowExempt('progressed/modifier/applying'), isTrue);
    expect(isShadowExempt('progressed/moon_in_sign/aries'), isFalse);
  });

  test('solar return without birth time still finds the moment', () {
    final natal = Chart.compute(const BirthData(moment: LocalMoment(year: 1990, month: 6, day: 15, zone: 'Europe/Prague'), lat: 50.08, lon: 14.42));
    final sr = SolarReturn.current(natal, julianDay(2026, 11, 20, 12));
    expect(sr.year, 2026);
    expect(sr.jdUt, lessThan(julianDay(2026, 11, 20, 12)));
    expect(Progression.at(natal, julianDay(2026, 11, 20, 12)).houses, isNull);
  });
}
