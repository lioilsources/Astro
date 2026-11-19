import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

List<Map<String, dynamic>> _load(String name) =>
    (jsonDecode(File('test/golden/$name').readAsStringSync()) as List).cast<Map<String, dynamic>>();

void main() {
  final planets = _load('planets.json');
  final houses = _load('houses.json');

  group('planets vs DE440', () {
    for (final body in Body.planets) {
      test(body.name, () {
        var worst = 0.0;
        for (final row in planets) {
          final jde = (row['jde'] as num).toDouble();
          final ref = row['bodies'][body.name];
          final got = Ephemeris.lonLatTT(body, jde);
          final dLon = angDist(got.lon, (ref['lon'] as num).toDouble()) * 60;
          final dLat = (got.lat - (ref['lat'] as num).toDouble()).abs() * 60;
          if (dLon > worst) worst = dLon;
          expect(dLon, lessThan(1.0), reason: '${body.name} lon at JDE $jde: $dLon′');
          expect(dLat, lessThan(1.0), reason: '${body.name} lat at JDE $jde: $dLat′');
        }
        printOnFailure('${body.name} worst ${worst.toStringAsFixed(3)}′');
      });
    }
  });

  test('nodes vs Swiss Ephemeris', () {
    for (final row in planets) {
      final jde = (row['jde'] as num).toDouble();
      expect(angDist(Ephemeris.lonLatTT(Body.meanNode, jde).lon, (row['meanNode'] as num).toDouble()) * 60, lessThan(1.0));
      expect(angDist(Ephemeris.lonLatTT(Body.trueNode, jde).lon, (row['trueNode'] as num).toDouble()) * 60, lessThan(1.0));
    }
  });

  test('sidereal time and obliquity', () {
    for (final row in planets) {
      final jdUt = (row['jdUt'] as num).toDouble();
      final jde = (row['jde'] as num).toDouble();
      expect(angDist(Ephemeris.apparentSiderealDeg(jdUt), (row['siderealDeg'] as num).toDouble()) * 3600, lessThan(3.0));
      expect((Ephemeris.trueObliquity(jde) - (row['obliquity'] as num).toDouble()).abs() * 3600, lessThan(1.0));
    }
  });

  test('ΔT within tolerance of skyfield', () {
    for (final row in planets) {
      final jde = (row['jde'] as num).toDouble();
      final year = decimalYearOfJd(jde);
      final ref = (row['deltaT'] as num).toDouble();
      if (year > 2030) continue; // future ΔT is a forecast in both models
      final tol = year < 1800 ? 30.0 : (year < 1955 ? 5.0 : (year < 2030 ? 1.5 : 100.0));
      expect((deltaTSeconds(year) - ref).abs(), lessThan(tol), reason: 'year $year: ${deltaTSeconds(year)} vs $ref');
    }
  });

  group('houses vs Swiss Ephemeris (same RAMC, latitude, obliquity)', () {
    for (final system in HouseSystem.values) {
      test(system.name, () {
        for (final row in houses) {
          final ref = row['systems'][system.name] as List?;
          if (ref == null) continue;
          final lat = (row['lat'] as num).toDouble();
          // Inside the polar circle Swiss Ephemeris swaps MC and IC for these two
          // systems; we keep the MC above. Porphyry is the default there anyway.
          if (lat.abs() > 66 && (system == HouseSystem.regiomontanus || system == HouseSystem.campanus)) continue;
          final r = housesFromRamc(system, (row['ramc'] as num).toDouble(), lat, (row['eps'] as num).toDouble());
          expect(r.defined, isTrue);
          for (var i = 0; i < 12; i++) {
            final d = angDist(r.cusps![i], (ref[i] as num).toDouble()) * 60;
            expect(d, lessThan(1.0), reason: '${system.name} lat $lat ramc ${row['ramc']} cusp ${i + 1}: ${r.cusps![i]} vs ${ref[i]}');
          }
          expect(angDist(r.asc, (row['asc'] as num).toDouble()) * 60, lessThan(1.0));
          expect(angDist(r.mc, (row['mc'] as num).toDouble()) * 60, lessThan(1.0));
        }
      });
    }
  });
}
