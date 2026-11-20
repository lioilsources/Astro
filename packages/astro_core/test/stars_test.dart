import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:test/test.dart';

void main() {
  final golden = (jsonDecode(File('test/golden/stars.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
  FixedStar star(String id) => fixedStars.firstWhere((s) => s.id == id);

  test('catalog has the 32 stars of plan 10.6', () {
    expect(fixedStars.length, 32);
    expect(starIds.toSet().length, 32);
    expect(starTargetIds.length, 12);
  });

  group('longitudes vs skyfield + DE440', () {
    for (final year in [1800, 2000]) {
      test('five stars, $year', () {
        final row = golden.firstWhere((r) => r['year'] == year);
        final jde = (row['jde'] as num).toDouble();
        for (final id in ['aldebaran', 'regulus', 'spica', 'algol', 'sirius']) {
          final ref = (row['stars'][id]['lon'] as num).toDouble();
          final d = angDist(star(id).longitudeTT(jde), ref) * 3600;
          expect(d, lessThan(2), reason: '$id $year: $d″');
        }
      });
    }

    test('all stars, all golden years, within 5″', () {
      var worst = 0.0;
      for (final row in golden) {
        final jde = (row['jde'] as num).toDouble();
        for (final s in fixedStars) {
          final ref = row['stars'][s.id];
          final d = angDist(s.longitudeTT(jde), (ref['lon'] as num).toDouble()) * 3600;
          final dl = (s.positionTT(jde).lat - (ref['lat'] as num).toDouble()).abs() * 3600;
          if (d > worst) worst = d;
          expect(d, lessThan(5), reason: '${s.id} ${row['year']}: lon $d″');
          expect(dl, lessThan(5), reason: '${s.id} ${row['year']}: lat $dl″');
        }
      }
      printOnFailure('worst ${worst.toStringAsFixed(2)}″');
    });
  });

  group('conjunction finder (orb 1°)', () {
    final jde = 2451545.0;
    final lons = starLongitudes(jde);
    final regulus = lons[star('regulus')]!;

    test('0.9° is a hit, 1.1° is not', () {
      final hit = findStarContacts({const ChartPoint.body(Body.mars): regulus + 0.9}, lons);
      expect(hit.map((c) => c.star.id), contains('regulus'));
      expect(hit.firstWhere((c) => c.star.id == 'regulus').orb, closeTo(0.9, 1e-9));
      final miss = findStarContacts({const ChartPoint.body(Body.mars): regulus - 1.1}, lons);
      expect(miss.map((c) => c.star.id), isNot(contains('regulus')));
    });

    test('angles count, nodes do not', () {
      final r = findStarContacts({
        const ChartPoint.angle(Angle.mc): regulus + 0.3,
        const ChartPoint.body(Body.meanNode): regulus,
      }, lons);
      expect(r.map((c) => c.point), [const ChartPoint.angle(Angle.mc)]);
    });

    test('chart exposes contacts and one star factor per star', () {
      for (var y = 1900; y <= 2100; y += 13) {
        final c = Chart.compute(BirthData(
          moment: LocalMoment(year: y, month: 5, day: 3, hour: 7, minute: 0, basis: TimeBasis.ut),
          lat: 50.08,
          lon: 14.42,
        ));
        for (final s in c.starContacts) {
          expect(s.orb, lessThanOrEqualTo(starOrb));
          expect(angDist(c.lonOf(s.point)!, s.starLon), closeTo(s.orb, 1e-9));
        }
        final f = factorsOf(c).where((f) => f.kind == FactorKind.star).toList();
        expect(f.map((x) => x.key).toSet().length, f.length);
        expect(f.length, c.starContacts.map((s) => s.star.id).toSet().length);
      }
    });
  });
}
